#!/usr/bin/env node
/**
 * CWP MCP Server
 * Model Context Protocol server for CWP (Control Web Panel) API integration
 *
 * Provides 17 tools for managing CWP servers:
 * - Account management (create, delete, suspend, unsuspend, list)
 * - Database management (create, delete, list)
 * - Email management (create, list)
 * - DNS management (add zone, add record)
 * - SSL management (install)
 * - Service management (restart, status)
 * - Backup management (create, restore)
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

/**
 * Sanitize input to prevent command injection
 */
function sanitizeInput(input) {
  if (typeof input !== "string") return "";
  // Only allow alphanumeric, hyphens, dots, underscores, slashes
  return input.replace(/[^a-zA-Z0-9\-._/]/g, "");
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
 * Define available tools
 */
const TOOLS = [
  {
    name: "cwp_account_create",
    description: "Create a new CWP user account with domain, username, password, and email",
    inputSchema: {
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
      type: "object",
      properties: {},
    },
  },
  {
    name: "cwp_database_create",
    description: "Create a MySQL database for a CWP account",
    inputSchema: {
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
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
      },
      required: ["username"],
    },
  },
  {
    name: "cwp_email_create",
    description: "Create an email account for a domain",
    inputSchema: {
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
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name" },
      },
      required: ["domain"],
    },
  },
  {
    name: "cwp_dns_add_zone",
    description: "Add a DNS zone for a domain",
    inputSchema: {
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
  {
    name: "cwp_ssl_install",
    description: "Install SSL certificate via AutoSSL for a domain",
    inputSchema: {
      type: "object",
      properties: {
        domain: { type: "string", description: "Domain name for SSL" },
      },
      required: ["domain"],
    },
  },
  {
    name: "cwp_service_restart",
    description: "Restart a CWP service (httpd, nginx, mariadb, postfix, etc.)",
    inputSchema: {
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
      type: "object",
      properties: {
        service: { type: "string", description: "Service name" },
      },
      required: ["service"],
    },
  },
  {
    name: "cwp_backup_create",
    description: "Create a backup for a CWP user account",
    inputSchema: {
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
      type: "object",
      properties: {
        username: { type: "string", description: "Account username" },
        backup_file: { type: "string", description: "Path to backup file" },
      },
      required: ["username", "backup_file"],
    },
  },
];

/**
 * Create MCP server
 */
const server = new Server(
  {
    name: "cwp-mcp-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * Handle list tools request
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

/**
 * Handle call tool request
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;

    switch (name) {
      case "cwp_account_create":
        result = await cwpApiCall("account", "add", {
          domain: args.domain,
          user: args.username,
          pass: args.password,
          email: args.email,
          package: args.package || "default",
          inode: "0",
          limit_nproc: "40",
          limit_nofile: "100",
          server_ips: CWP_HOST,
        });
        break;

      case "cwp_account_delete":
        result = await cwpApiCall("account", "del", {
          user: args.username,
          email: `admin@${CWP_HOST}`,
        });
        break;

      case "cwp_account_suspend":
        result = await cwpApiCall("account", "susp", {
          user: args.username,
        });
        break;

      case "cwp_account_unsuspend":
        result = await cwpApiCall("account", "unsp", {
          user: args.username,
        });
        break;

      case "cwp_account_list":
        result = await cwpApiCall("account", "list");
        break;

      case "cwp_database_create":
        result = await cwpApiCall("databasemysql", "add", {
          user: args.username,
          database: args.dbname,
        });
        break;

      case "cwp_database_delete":
        result = await cwpApiCall("databasemysql", "del", {
          user: args.username,
          database: args.dbname,
        });
        break;

      case "cwp_database_list":
        result = await cwpApiCall("databasemysql", "list", {
          user: args.username,
        });
        break;

      case "cwp_email_create":
        result = await cwpApiCall("email", "add", {
          domain: args.domain,
          user: args.username,
          pass: args.password,
        });
        break;

      case "cwp_email_list":
        result = await cwpApiCall("email", "list", {
          domain: args.domain,
        });
        break;

      case "cwp_dns_add_zone":
        result = await cwpApiCall("admindomains", "add", {
          user: "admin",
          type: "domain",
          name: args.domain,
        });
        break;

      case "cwp_dns_add_record":
        result = await cwpApiCall("admindomains", "add", {
          user: "admin",
          type: "record",
          domain: args.domain,
          record_type: args.type,
          name: args.name,
          value: args.value,
          ttl: args.ttl || "14400",
        });
        break;

      case "cwp_ssl_install":
        result = await cwpApiCall("autossl", "add", {
          user: "admin",
          name: args.domain,
        });
        break;

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

      case "cwp_backup_create": {
        const user = sanitizeInput(args.username);
        if (!user || user.length < 3) {
          throw new Error("Invalid username for backup");
        }
        result = {
          status: "OK",
          message: await execCommand(
            `sh /scripts/user_backup ${user} 2>&1 || echo "Backup initiated"`
          ),
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
        // Prevent path traversal attacks
        if (backupFile.includes("..")) {
          throw new Error("Invalid backup file path (path traversal detected)");
        }
        // Ensure backup file is in an allowed directory
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
  console.error("CWP MCP Server running on stdio");
}

main().catch(console.error);
