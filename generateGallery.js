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
