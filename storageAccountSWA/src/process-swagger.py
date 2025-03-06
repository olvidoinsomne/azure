import os
import json
import shutil  # Added for copying files

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))  # Location of process-swagger.py
STAGING_FOLDER = os.getenv("STAGING_FOLDER", os.path.join(SCRIPT_DIR, "./staging"))  # Staging folder
ORIGINAL_INDEX_HTML_PATH = os.path.join(SCRIPT_DIR, "index.html")  # Original index.html in script folder
INDEX_HTML_PATH = os.path.join(STAGING_FOLDER, "index.html")  # Copy inside staging folder
ORIGINAL_SWAGGER_INIT_PATH = os.path.join(SCRIPT_DIR, "swagger-initializer.js")  # Original swagger-initializer.js
SWAGGER_INIT_FILE = os.path.join(STAGING_FOLDER, "swagger-initializer.js")  # Copy inside staging folder

def copy_static_files():
    """Copy index.html and swagger-initializer.js from script folder to staging folder."""
    if not os.path.exists(STAGING_FOLDER):
        os.makedirs(STAGING_FOLDER)  # Ensure the staging folder exists

    # Copy index.html
    if os.path.exists(ORIGINAL_INDEX_HTML_PATH):
        print(f"📄 Copying index.html from {ORIGINAL_INDEX_HTML_PATH} to {INDEX_HTML_PATH}")
        shutil.copy(ORIGINAL_INDEX_HTML_PATH, INDEX_HTML_PATH)
    else:
        print(f"⚠ index.html not found in {SCRIPT_DIR}. Creating a new blank index.html.")
        with open(INDEX_HTML_PATH, "w", encoding="utf-8") as f:
            f.write("<html><body><h1>API Documentation</h1><div id='service-list'></div></body></html>")

    # Copy swagger-initializer.js
    if os.path.exists(ORIGINAL_SWAGGER_INIT_PATH):
        print(f"📄 Copying swagger-initializer.js from {ORIGINAL_SWAGGER_INIT_PATH} to {SWAGGER_INIT_FILE}")
        shutil.copy(ORIGINAL_SWAGGER_INIT_PATH, SWAGGER_INIT_FILE)
    else:
        print(f"⚠ swagger-initializer.js not found in {SCRIPT_DIR}. Creating a new blank swagger-initializer.js.")
        with open(SWAGGER_INIT_FILE, "w", encoding="utf-8") as f:
            f.write("window.swaggerFiles = [];")

def get_all_json_files():
    """Recursively find all .json files inside the staging folder and return relative paths."""
    json_files = []
    for root, _, files in os.walk(STAGING_FOLDER):
        for file in files:
            if file.endswith(".json"):
                # Get the relative path for Swagger UI
                relative_path = os.path.relpath(os.path.join(root, file), STAGING_FOLDER)
                json_files.append(relative_path)

    json_files.sort()  # Ensure alphabetical order
    return json_files

def process_json_files():
    """Process JSON files and update swagger-initializer.js."""
    print(f"🔍 Searching for JSON files in: {STAGING_FOLDER}")
    
    json_files = get_all_json_files()
    if not json_files:
        print("⚠ No JSON files found in staging directory!")
        return

    swagger_entries = [f"\"{file}\"" for file in json_files]

    # Update swagger-initializer.js inside staging/
    print(f"📄 Updating {SWAGGER_INIT_FILE} with {len(swagger_entries)} API files...")
    with open(SWAGGER_INIT_FILE, "w", encoding="utf-8") as f:
        f.write(f"window.swaggerFiles = [{', '.join(swagger_entries)}];")

def update_index_html():
    """Update the copied index.html inside staging with API links."""
    if not os.path.exists(INDEX_HTML_PATH):
        print(f"⚠ index.html not found in staging folder after copying. Skipping update.")
        return

    with open(INDEX_HTML_PATH, "r", encoding="utf-8") as f:
        index_html = f.read()

    # Replace the "row" section with new services
    new_rows = "\n".join(
        [f'<div class="service-row">{file}</div>' for file in get_all_json_files()]
    )

    if "<!-- row -->" in index_html:
        print("✅ Found placeholder '<!-- row -->' in index.html. Updating...")
        index_html = index_html.replace("<!-- row -->", new_rows)
    else:
        print("⚠ Placeholder '<!-- row -->' not found. Appending service rows to the bottom of the file.")
        index_html += f"\n<div id='service-list'>\n{new_rows}\n</div>"

    with open(INDEX_HTML_PATH, "w", encoding="utf-8") as f:
        f.write(index_html)

if __name__ == "__main__":
    copy_static_files()  # Step 1: Copy index.html & swagger-initializer.js to staging
    process_json_files()  # Step 2: Process JSON files & update swagger-initializer.js
    update_index_html()  # Step 3: Modify the copied index.html
