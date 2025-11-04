# Test Image Assets

This directory contains test images for acceptance testing.

## Required Images

1. **pothole_sample_1.jpg** - Valid pothole image (< 10MB)
2. **streetlight_broken.jpg** - Valid streetlight image (< 10MB)
3. **graffiti_sample.jpg** - Valid graffiti image (< 10MB)
4. **huge_image.jpg** - Image > 10MB for size limit testing
5. **inappropriate_content.jpg** - Image for SafeSearch validation testing
6. **document.pdf** - PDF file for invalid format testing

## Creating Test Images

The current files are placeholders. Replace them with actual images:

```bash
# Example using ImageMagick to create test images
convert -size 800x600 xc:gray -pointsize 40 -fill black \
    -annotate +100+300 "Test Pothole Image" \
    pothole_sample_1.jpg

# Create huge image (>10MB)
convert -size 4000x3000 xc:white huge_image.jpg
```

## Notes

- All valid images should be JPEG or PNG format
- Valid images should be < 10MB per spec requirement (FR-008)
- huge_image.jpg must be > 10MB to test rejection
- inappropriate_content.jpg should trigger SafeSearch (mocked in tests)
- document.pdf should be a valid PDF to test format validation
