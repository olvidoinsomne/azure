# Swagger Static Web App

## Overview
This repository automates the deployment of a **Static Web App (SWA)** in Azure that dynamically displays Swagger API documentation.

## Purpose
To automate the creation of API documentation by the following:

- Fetches Swagger assets and `index.html` from an **Azure Storage Account**.
- Processes API JSON files using a **Python script (`process_swagger.py`)**.
- Dynamically updates to display available APIs.
- Modifies `index.html` to allow users to select and view Swagger API documentation.
- Deploys the updated files to **Azure Static Web App** via an **Azure DevOps pipeline**.

## How It Works
1. **Azure DevOps Pipeline (`azure-pipelines.yml`)**:
   - Downloads Swagger assets from an Azure Storage Account.
   - Runs `process_swagger.py` to update JSON files and Swagger UI.
   - Deploys the updated `index.html`, JSON files, and `swagger-initializer.js` to SWA.

2. **Python Script (`process_swagger.py`)**:
   - Iterates through `.json` files, updating metadata and `.ninja` fields.
   - Updates `swagger-initializer.js` to include all available APIs.
   - Modifies `index.html` to dynamically list and display APIs.

## Deployment
- The Azure DevOps pipeline automatically deploys the latest Swagger documentation to **Azure Static Web Apps**.
- The `index.html` dynamically loads and displays available APIs from `swagger-initializer.js`.

---
This repo ensures that **Swagger API documentation stays updated and accessible** via Azure Static Web Apps seperated out by environment.