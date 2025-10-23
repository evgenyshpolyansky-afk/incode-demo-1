# Use a lightweight Python image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY ./* .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8080
EXPOSE 8080

# Default command to run the app
CMD ["python3", "app.py"]

# EXAMPLE TO RUN
# docker run -p 8080:8080 -e DB_ENDPOINT=${DB_ENDPOINT} -e DB_USERNAME=${DB_USERNAME} -e DB_PASSWORD=${DB_PASSWORD} IMAGE_ID