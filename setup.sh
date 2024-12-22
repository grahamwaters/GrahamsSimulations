#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1 ;
}

echo "=== Simulation Gallery Setup Script ==="

# 1. Check for Node.js and npm
if command_exists node && command_exists npm; then
    echo "✔ Node.js and npm are already installed."
else
    echo "✖ Node.js and/or npm are not installed."
    echo "Please install Node.js (which includes npm) before running this script."
    echo "Visit https://nodejs.org/ to download and install."
    exit 1
fi

# 2. Check for Git
if command_exists git; then
    echo "✔ Git is installed."
else
    echo "✖ Git is not installed."
    echo "Please install Git before running this script."
    echo "Visit https://git-scm.com/downloads to download and install."
    exit 1
fi

# 3. Initialize npm if package.json does not exist
if [ ! -f package.json ]; then
    echo "Initializing npm..."
    npm init -y
else
    echo "✔ package.json already exists."
fi

# 4. Install Puppeteer
echo "Installing Puppeteer..."
npm install puppeteer

# 5. Create Directory Structure
echo "Creating directories..."

mkdir -p simulations
mkdir -p previews

echo "✔ Directories 'simulations/' and 'previews/' are set up."

# 6. Create generateGallery.js
echo "Creating 'generateGallery.js'..."

cat << 'EOF' > generateGallery.js
// generateGallery.js
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

// Configuration - Update these if necessary
const simulationsDir = path.join(__dirname, 'simulations');
const previewsDir = path.join(__dirname, 'previews');
const outputFile = path.join(__dirname, 'index.html');

// Ensure previews directory exists
if (!fs.existsSync(previewsDir)) {
    fs.mkdirSync(previewsDir);
}

(async () => {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    const files = fs.readdirSync(simulationsDir).filter(file => file.endsWith('.html'));

    let galleryItems = '';

    for (const file of files) {
        const simName = path.parse(file).name;
        const simPath = `simulations/${file}`;
        const previewPath = `previews/${simName}.png`;

        // Generate preview screenshot
        const fileUrl = `file://${path.join(__dirname, simPath)}`;
        try {
            await page.goto(fileUrl, { waitUntil: 'networkidle0' });
            await page.setViewport({ width: 800, height: 600 }); // Adjust as needed
            await page.screenshot({ path: previewPath, fullPage: true });
            console.log(`✔ Generated preview for ${file}`);
        } catch (error) {
            console.error(`✖ Failed to generate preview for ${file}: ${error}`);
            continue;
        }

        // Create gallery item
        galleryItems += `
            <div class="gallery-item">
                <a href="${simPath}" target="_blank">
                    <img src="${previewPath}" alt="${simName}" />
                    <div class="overlay">${simName}</div>
                </a>
            </div>
        `;
    }

    await browser.close();

    // Generate index.html content
    const htmlContent = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Simulation Gallery</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f0f0f0;
                padding: 20px;
            }
            .gallery {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                gap: 20px;
            }
            .gallery-item {
                position: relative;
                overflow: hidden;
                border: 1px solid #ccc;
                border-radius: 8px;
                background-color: #fff;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            }
            .gallery-item img {
                width: 100%;
                height: auto;
                display: block;
            }
            .overlay {
                position: absolute;
                bottom: 0;
                background: rgba(0, 0, 0, 0.6);
                color: #fff;
                width: 100%;
                text-align: center;
                padding: 10px;
                box-sizing: border-box;
                opacity: 0;
                transition: opacity 0.3s;
            }
            .gallery-item:hover .overlay {
                opacity: 1;
            }
            a {
                text-decoration: none;
                color: inherit;
            }
        </style>
    </head>
    <body>
        <h1>Simulation Gallery</h1>
        <div class="gallery">
            ${galleryItems}
        </div>
    </body>
    </html>
    `;

    // Write to index.html
    fs.writeFileSync(outputFile, htmlContent);
    console.log("✔ 'index.html' has been generated successfully.");
})();
EOF

echo "✔ 'generateGallery.js' created."

# 7. Update package.json with build scripts
echo "Updating 'package.json' with build scripts..."

# Check if "scripts" exists and update accordingly
if grep -q '"scripts":' package.json; then
    # Use jq to modify package.json if available
    if command_exists jq; then
        jq '.scripts += { "generate": "node generateGallery.js", "build": "npm run generate" }' package.json > tmp.json && mv tmp.json package.json
        echo "✔ Added 'generate' and 'build' scripts to package.json using jq."
    else
        # If jq is not available, append scripts manually
        echo "✔ Adding 'generate' and 'build' scripts manually to package.json."
        sed -i '/"scripts": {/a \
        \    "generate": "node generateGallery.js",\
        \    "build": "npm run generate",' package.json
    fi
else
    # If "scripts" does not exist, add it
    echo "✔ Adding 'scripts' section to package.json."
    sed -i '/^{/a \
    "scripts": {\
        "generate": "node generateGallery.js",\
        "build": "npm run generate"\
    },' package.json
fi

echo "✔ 'package.json' updated."

# 8. Create a sample index.html if not present (optional)
if [ ! -f index.html ]; then
    echo "Creating a sample 'index.html'..."
    node generateGallery.js
else
    echo "✔ 'index.html' already exists. It will be overwritten when you run the build script."
fi

# 9. Provide GitHub Pages Setup Instructions
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next Steps:"
echo "1. Add your simulation HTML files to the 'simulations/' directory."
echo "2. Run the build script to generate previews and update 'index.html':"
echo "   \$ npm run build"
echo "3. Initialize a git repository (if not already) and commit your changes:"
echo "   \$ git init"
echo "   \$ git add ."
echo "   \$ git commit -m 'Initial commit with simulation gallery setup'"
echo "4. Push your repository to GitHub."
echo "5. Enable GitHub Pages in your repository settings:"
echo "   - Go to Settings > Pages"
echo "   - Select the branch (e.g., 'main') and root folder"
echo "   - Save to deploy your site."
echo ""
echo "Optional: To automate gallery generation on each commit, consider setting up GitHub Actions."
echo ""
echo "Enjoy your interactive simulation gallery!"
