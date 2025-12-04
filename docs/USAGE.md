# Usage Instructions for Interactive Feedback MCP

## Overview
The Interactive Feedback MCP (Multi-Channel Processor) is designed to facilitate interactive feedback mechanisms in various applications. This document provides instructions on how to run and interact with the MCP after installation.

## Prerequisites
Before using the MCP, ensure that you have completed the installation process using the `mcp1.sh` script. This includes verifying that Python 3.11 or higher and `uv` are installed and configured correctly.

## Running the MCP
To start the MCP server, navigate to the installation directory where the MCP was set up. You can do this by running:

```bash
cd ~/Dev/interactive-feedback-mcp
```

Once in the directory, execute the following command to run the server:

```bash
uv run server.py
```

This command will start the MCP process, which will wait for client requests.

## Configuration
The MCP server configuration is stored in the `~/.cursor/mcp.json` file. You can modify this file to change the server settings or add new configurations as needed.

## Interacting with the MCP
After starting the server, you can interact with it through the designated client applications. Ensure that the clients are configured to communicate with the MCP server.

## Troubleshooting
If you encounter issues while running the MCP, check the following:
- Ensure that all dependencies are installed correctly.
- Verify that the server is running and listening for requests.
- Check the logs for any error messages that may indicate what went wrong.

For further assistance, refer to the project's README.md or seek help from the community.