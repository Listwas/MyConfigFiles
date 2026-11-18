from PIL import Image

# Load the image
image = Image.open("image.png")

# Resize to the screen resolution
image = image.resize((320, 240))

# Convert to RGB565 format
def convert_to_rgb565(img):
    rgb565 = []
    for pixel in img.getdata():
        r, g, b = pixel
        rgb565.append((r & 0xF8) << 8 | (g & 0xFC) << 3 | (b >> 3))
    return rgb565

# Convert and save
image_rgb565 = convert_to_rgb565(image.convert("RGB"))
with open("image.raw", "wb") as f:
    for pixel in image_rgb565:
        f.write(pixel.to_bytes(2, "big"))
