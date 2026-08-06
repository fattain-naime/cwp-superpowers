#!/usr/bin/env node
/**
 * CWP MCP Server
 * Model Context Protocol server for CWP (Control Web Panel) API integration
 *
 * Provides 23 tools for managing CWP servers:
 * - Account management (create, delete, suspend, unsuspend, list)
 * - Database management (create, delete, list)
 * - Email management (create, list)
 * - DNS management (add zone, add record)
 * - SSL management (install)
 * - Service management (restart, status, list)
 * - Backup management (create, restore)
 * - Monitoring (log tail, security scan, health check, disk usage)
 * - PHP management (list versions)
 *
 * MCP Spec: 2026-07-28 compliant (SDK 1.30.0)
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import https from "node:https";

// Configuration from environment variables
const CWP_HOST = process.env.CWP_HOST || "localhost";
const CWP_API_KEY = process.env.CWP_API_KEY || "";
const CWP_API_PORT = process.env.CWP_API_PORT || "2304";
const CWP_SSL_VERIFY = process.env.CWP_SSL_VERIFY !== "false"; // Default: true

// Allowlist of valid CWP services for shell commands
const VALID_SERVICES = [
  "httpd", "nginx", "mariadb", "mysql", "postfix", "dovecot",
  "named", "pure-ftpd", "csf", "cwpsrv", "php-fpm", "varnish",
  "redis", "memcached", "fail2ban"
];

// Allowlist of safe log file paths for tailing
const SAFE_LOG_PATHS = [
  "/var/log/cwp/", "/var/log/nginx/", "/usr/local/apache/logs/",
  "/usr/local/apache/domlogs/", "/var/log/maillog", "/var/log/secure",
  "/var/lib/mysql/", "/var/log/varnish/", "/var/log/lfd.log",
  "/usr/local/cwpsrv/logs/", "/var/log/mysql/", "/var/log/cron",
  "/var/log/rspamd/", "/var/log/clamd.scan"
];

// Task store for long-running operations
const tasks = new Map();
let taskCounter = 0;

/**
 * Sanitize input to prevent command injection
 */
function sanitizeInput(input) {
  if (typeof input !== "string") return "";
  return input.replace(/[^a-zA-Z0-9\-._/]/g, "");
}

/**
 * Sanitize input for API calls (broader than shell sanitizer)
 */
function sanitizeApiInput(input) {
  if (typeof input !== "string") return "";
  return input.replace(/[^a-zA-Z0-9\-._@ ]/g, "");
}

/**
 * Validate log path is in an allowed directory
 */
function validateLogPath(path) {
  const sanitized = sanitizeInput(path);
  if (!sanitized) throw new Error("Invalid log path");
  if (sanitized.includes("..")) throw new Error("Path traversal detected");
  const allowed = SAFE_LOG_PATHS.some(p => sanitized.startsWith(p));
  if (!allowed) throw new Error(`Log path must be in: ${SAFE_LOG_PATHS.join(", ")}`);
  return sanitized;
}

/**
 * Create a task for long-running operations
 */
function createTask(name, status = "running") {
  const taskId = `task_${++taskCounter}`;
  tasks.set(taskId, { id: taskId, name, status, result: null, created: Date.now() });
  return taskId;
}

/**
 * Update task status
 */
function updateTask(taskId, status, result = null) {
  const task = tasks.get(taskId);
  if (task) {
    task.status = status;
    task.result = result;
    task.updated = Date.now();
  }
}

/**
 * Make API call to CWP
 */
async function cwpApiCall(endpoint, action, params = {}) {
  return new Promise((resolve, reject) => {
    const url = `https://${CWP_HOST}:${CWP_API_PORT}/v1/${endpoint}`;

    const postData = new URLSearchParams({
      key: CWP_API_KEY,
      action: action,
      ...params,
    }).toString();

    const options = {
      method: "POST",
      rejectUnauthorized: CWP_SSL_VERIFY,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": Buffer.byteLength(postData),
      },
    };

    const req = https.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve({ raw: data });
        }
      });
    });

    req.setTimeout(30000, () => {
      req.destroy(new Error("API request timed out after 30s"));
    });

    req.on("timeout", () => {
      req.destroy(new Error("API request timed out after 30s"));
    });

    req.on("error", reject);
    req.write(postData);
    req.end();
  });
}

/**
 * Execute shell command and return output
 */
async function execCommand(cmd) {
  const { execSync } = await import("node:child_process");
  try {
    return execSync(cmd, { encoding: "utf-8", timeout: 30000 }).trim();
  } catch (error) {
    return `Error: ${error.message}`;
  }
}

/**
 * Define available tools (23 tools, MCP Spec 2026-07-28)
 */
const TOOLS = [
  // --- Account Management ---
  {
    name: "cwp_account_create",
    description: "Create a new CWP user account with domain, username, password, and email",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        domain: { type: "string", description: "Main domain for the account" },
        username: { type: "string", description: "Username (6-8 lowercase letters)" },
        password: { type: "string", description: "Account password" },
        email: { type: "string", description: "Account owner email" },
        package: { type: "string", description: "Package name", default: "default" },
      },
      required: ["domain", "username", "password", "email"],
    },
  },
  {
    name: "cwp_account_delete",
    description: "Delete a CWP user account permanently",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Username to delete" },
      },
      required: ["username"],
    },
  },
  {
    name: "cwp_account_suspend",
    description: "Suspend a CWP user account",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Username to suspend" },
      },
      required: ["username"],
    },
  },
  {
    name: "cwp_account_unsuspend",
    description: "Unsuspend a previously suspended CWP user account",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Username to unsuspend" },
      },
      required: ["username"],
    },
  },
  {
    name: "cwp_account_list",
    description: "List all CWP user accounts",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {},
    },
  },
  // --- Database Management ---
  {
    name: "cwp_database_create",
    description: "Create a MySQL database for a CWP account",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
        dbname: { type: "string", description: "Database name" },
      },
      required: ["username", "dbname"],
    },
  },
  {
    name: "cwp_database_delete",
    description: "Delete a MySQL database",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
        dbname: { type: "string", description: "Database name" },
      },
      required: ["username", "dbname"],
    },
  },
  {
    name: "cwp_database_list",
    description: "List databases for a CWP account",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
      },
      required: ["username"],
    },
  },
  // --- Email Management ---
  {
    name: "cwp_email_create",
    description: "Create an email account for a domain",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name" },
        username: { type: "string", description: "Email username (before @)" },
        password: { type: "string", description: "Email password" },
      },
      required: ["domain", "username", "password"],
    },
  },
  {
    name: "cwp_email_list",
    description: "List email accounts for a domain",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name" },
      },
      required: ["domain"],
    },
  },
  // --- DNS Management ---
  {
    name: "cwp_dns_add_zone",
    description: "Add a DNS zone for a domain",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name" },
        ip: { type: "string", description: "IP address for the zone" },
      },
      required: ["domain", "ip"],
    },
  },
  {
    name: "cwp_dns_add_record",
    description: "Add a DNS record to an existing zone",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name" },
        type: { type: "string", description: "Record type (A, AAAA, MX, TXT, CNAME, SRV)" },
        name: { type: "string", description: "Record name (e.g., www, mail, @)" },
        value: { type: "string", description: "Record value" },
        ttl: { type: "number", description: "TTL in seconds", default: 14400 },
      },
      required: ["domain", "type", "name", "value"],
    },
  },
  // --- SSL Management ---
  {
    name: "cwp_ssl_install",
    description: "Install SSL certificate via AutoSSL for a domain",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name for SSL" },
      },
      required: ["domain"],
    },
  },
  // --- Service Management ---
  {
    name: "cwp_service_restart",
    description: "Restart a CWP service (httpd, nginx, mariadb, postfix, etc.)",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        service: {
          type: "string",
          description: "Service name (httpd, nginx, mariadb, postfix, dovecot, named, pure-ftpd)",
        },
      },
      required: ["service"],
    },
  },
  {
    name: "cwp_service_status",
    description: "Check the status of a CWP service",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        service: { type: "string", description: "Service name" },
      },
      required: ["service"],
    },
  },
  {
    name: "cwp_service_list",
    description: "List all CWP services and their status (running/stopped/unknown)",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {},
    },
  },
  // --- Backup Management ---
  {
    name: "cwp_backup_create",
    description: "Create a backup for a CWP user account",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
      },
      required: ["username"],
    },
  },
  {
    name: "cwp_backup_restore",
    description: "Restore a CWP user account from backup",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
        backup_file: { type: "string", description: "Path to backup file (must be in /backup/)" },
      },
      required: ["username", "backup_file"],
    },
  },
  // --- Monitoring & Diagnostics ---
  {
    name: "cwp_log_tail",
    description: "Tail the last N lines of a CWP/server log file",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {
        log_path: { type: "string", description: "Full path to log file" },
        lines: { type: "number", description: "Number of lines to tail", default: 50 },
      },
      required: ["log_path"],
    },
  },
  {
    name: "cwp_security_scan",
    description: "Run a quick security scan checking SSH, firewall, SSL, and updates",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {},
    },
  },
  {
    name: "cwp_health_check",
    description: "Quick health check of all critical CWP services and resources",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {},
    },
  },
  {
    name: "cwp_php_versions",
    description: "List all installed PHP versions on the server",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {},
    },
  },
  {
    name: "cwp_disk_usage",
    description: "Show disk usage by user and partition",
    inputSchema: {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      type: "object",
      properties: {},
    },
  },
];

/**
 * Create MCP server (MCP Spec 2026-07-28)
 */
const server = new Server(
  {
    name: "cwp-mcp-server",
    version: "1.1.0",
  },
  {
    capabilities: {
      tools: { listChanged: true },
      extensions: {},
    },
  }
);

/**
 * Handle list tools request (with caching hints)
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: TOOLS,
    ttlMs: 300000,       // Cache for 5 minutes
    cacheScope: "public", // Shared caching allowed
  };
});

/**
 * Handle call tool request
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;

    switch (name) {
      // --- Account Management ---
      case "cwp_account_create":
        result = await cwpApiCall("account", "add", {
          domain: sanitizeApiInput(args.domain),
          user: sanitizeApiInput(args.username),
          pass: args.password,
          email: sanitizeApiInput(args.email),
          package: sanitizeApiInput(args.package || "default"),
          inode: "0",
          limit_nproc: "40",
          limit_nofile: "100",
          server_ips: CWP_HOST,
        });
        break;

      case "cwp_account_delete":
        result = await cwpApiCall("account", "del", {
          user: sanitizeApiInput(args.username),
          email: `admin@${CWP_HOST}`,
        });
        break;

      case "cwp_account_suspend":
        result = await cwpApiCall("account", "susp", {
          user: sanitizeApiInput(args.username),
        });
        break;

      case "cwp_account_unsuspend":
        result = await cwpApiCall("account", "unsp", {
          user: sanitizeApiInput(args.username),
        });
        break;

      case "cwp_account_list":
        result = await cwpApiCall("account", "list");
        break;

      // --- Database Management ---
      case "cwp_database_create":
        result = await cwpApiCall("databasemysql", "add", {
          user: sanitizeApiInput(args.username),
          database: sanitizeApiInput(args.dbname),
        });
        break;

      case "cwp_database_delete":
        result = await cwpApiCall("databasemysql", "del", {
          user: sanitizeApiInput(args.username),
          database: sanitizeApiInput(args.dbname),
        });
        break;

      case "cwp_database_list":
        result = await cwpApiCall("databasemysql", "list", {
          user: sanitizeApiInput(args.username),
        });
        break;

      // --- Email Management ---
      case "cwp_email_create":
        result = await cwpApiCall("email", "add", {
          domain: sanitizeApiInput(args.domain),
          user: sanitizeApiInput(args.username),
          pass: args.password,
        });
        break;

      case "cwp_email_list":
        result = await cwpApiCall("email", "list", {
          domain: sanitizeApiInput(args.domain),
        });
        break;

      // --- DNS Management ---
      case "cwp_dns_add_zone":
        result = await cwpApiCall("admindomains", "add", {
          user: "admin",
          type: "domain",
          name: sanitizeApiInput(args.domain),
        });
        break;

      case "cwp_dns_add_record":
        result = await cwpApiCall("admindomains", "add", {
          user: "admin",
          type: "record",
          domain: sanitizeApiInput(args.domain),
          record_type: sanitizeApiInput(args.type),
          name: sanitizeApiInput(args.name),
          value: sanitizeApiInput(args.value),
          ttl: String(args.ttl || "14400"),
        });
        break;

      // --- SSL Management ---
      case "cwp_ssl_install":
        result = await cwpApiCall("autossl", "add", {
          user: "admin",
          name: sanitizeApiInput(args.domain),
        });
        break;

      // --- Service Management ---
      case "cwp_service_restart": {
        const svc = sanitizeInput(args.service);
        if (!VALID_SERVICES.includes(svc)) {
          throw new Error(`Invalid service: ${args.service}. Allowed: ${VALID_SERVICES.join(", ")}`);
        }
        result = {
          status: "OK",
          message: await execCommand(
            `systemctl restart ${svc} 2>&1 && echo "restarted" || echo "failed"`
          ),
        };
        break;
      }

      case "cwp_service_status": {
        const svc = sanitizeInput(args.service);
        if (!VALID_SERVICES.includes(svc)) {
          throw new Error(`Invalid service: ${args.service}. Allowed: ${VALID_SERVICES.join(", ")}`);
        }
        const status = await execCommand(
          `systemctl is-active ${svc} 2>/dev/null || echo "inactive"`
        );
        result = { status: "OK", service: svc, state: status };
        break;
      }

      case "cwp_service_list": {
        const statuses = {};
        for (const svc of VALID_SERVICES) {
          const st = await execCommand(
            `systemctl is-active ${svc} 2>/dev/null || echo "unknown"`
          );
          statuses[svc] = st;
        }
        result = { status: "OK", services: statuses };
        break;
      }

      // --- Backup Management ---
      case "cwp_backup_create": {
        const user = sanitizeInput(args.username);
        if (!user || user.length < 3) {
          throw new Error("Invalid username for backup");
        }
        const taskId = createTask(`backup_${user}`);
        execCommand(`sh /scripts/user_backup ${user} 2>&1`)
          .then(r => updateTask(taskId, "completed", r))
          .catch(e => updateTask(taskId, "failed", e.message));
        result = {
          status: "OK",
          taskId,
          message: `Backup initiated for ${user}. Use cwp_task_get to check progress.`,
        };
        break;
      }

      case "cwp_backup_restore": {
        const user = sanitizeInput(args.username);
        const backupFile = sanitizeInput(args.backup_file);
        if (!user || user.length < 3) {
          throw new Error("Invalid username for restore");
        }
        if (!backupFile || !backupFile.endsWith(".tar.gz")) {
          throw new Error("Invalid backup file (must be .tar.gz)");
        }
        if (backupFile.includes("..")) {
          throw new Error("Invalid backup file path (path traversal detected)");
        }
        if (!backupFile.startsWith("/backup/")) {
          throw new Error("Backup file must be in /backup/ directory");
        }
        result = {
          status: "OK",
          message: await execCommand(
            `sh /scripts/restore_backup ${user} ${backupFile} 2>&1 || echo "Restore initiated"`
          ),
        };
        break;
      }

      // --- Monitoring & Diagnostics ---
      case "cwp_log_tail": {
        const logPath = validateLogPath(args.log_path);
        const lines = Math.min(Math.max(args.lines || 50, 1), 500);
        result = {
          status: "OK",
          log: logPath,
          lines,
          output: await execCommand(`tail -n ${lines} ${logPath} 2>&1`),
        };
        break;
      }

      case "cwp_security_scan": {
        const checks = {};
        checks.ssh_root_login = await execCommand(
          "grep -i '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo 'unknown'"
        );
        checks.ssh_password_auth = await execCommand(
          "grep -i '^PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo 'unknown'"
        );
        checks.csf_status = await execCommand("csf -e 2>/dev/null && echo 'enabled' || echo 'unknown'");
        checks.iptables_rules = await execCommand("iptables -L -n 2>/dev/null | wc -l");
        checks.letsencrypt_certs = await execCommand("ls /etc/letsencrypt/live/ 2>/dev/null | wc -l");
        checks.security_updates = await execCommand(
          "yum check-update --security --quiet 2>/dev/null | wc -l || echo '0'"
        );
        checks.listening_ports = await execCommand("ss -tlnp 2>/dev/null | grep LISTEN | wc -l");
        result = { status: "OK", scan: checks };
        break;
      }

      case "cwp_health_check": {
        const health = {};
        const criticalServices = ["httpd", "nginx", "mariadb", "postfix", "dovecot", "named", "cwpsrv"];
        for (const svc of criticalServices) {
          health[svc] = await execCommand(
            `systemctl is-active ${svc} 2>/dev/null || echo "inactive"`
          );
        }
        health.disk_root = await execCommand("df -h / | tail -1 | awk '{print $5}'");
        health.memory = await execCommand("free -m | awk '/Mem:/{printf \"%d%%\", $3/$2*100}'");
        health.load = await execCommand("cat /proc/loadavg | awk '{print $1}'");
        health.uptime = await execCommand("uptime -p 2>/dev/null || uptime");
        health.mysql_connections = await execCommand(
          "mysql -e 'SHOW STATUS LIKE \"Threads_connected\";' 2>/dev/null | awk '/Threads_connected/{print $2}' || echo 'unknown'"
        );
        result = { status: "OK", health };
        break;
      }

      case "cwp_php_versions": {
        const versions = await execCommand(
          "ls /opt/alt/ 2>/dev/null | grep '^php[0-9]' | sort"
        );
        const current = await execCommand("php -v 2>/dev/null | head -1 | awk '{print $2}'");
        result = {
          status: "OK",
          current,
          installed: versions.split("\n").filter(Boolean),
        };
        break;
      }

      case "cwp_disk_usage": {
        const partitions = await execCommand("df -h / /home /var /tmp 2>/dev/null");
        const userUsage = await execCommand("du -sh /home/*/ 2>/dev/null | sort -rh | head -10");
        result = {
          status: "OK",
          partitions,
          top_users: userUsage,
        };
        break;
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ error: error.message }, null, 2),
        },
      ],
      isError: true,
    };
  }
});

/**
 * Start server
 */
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("CWP MCP Server v1.1.0 running on stdio (MCP Spec 2026-07-28)");
}

main().catch(console.error);
