#!/bin/bash

# FYP MrSteam Web deployment script
# This script deploys the Flutter Web app to Google Cloud Platform

set -e  # Exit immediately on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function: print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check required tools
check_requirements() {
    print_message "Checking required tools..." $BLUE
    
    if ! command -v gcloud &> /dev/null; then
        print_message "Error: gcloud CLI not found. Please install Google Cloud SDK." $RED
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_message "Error: Docker not found. Please install Docker." $RED
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        print_message "Error: Flutter not found. Please install Flutter SDK." $RED
        exit 1
    fi
    
    print_message "✓ All required tools are installed" $GREEN
}

# Set GCP project and config variables
setup_project() {
    # First try to get current project from gcloud config
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    fi
    
    # If project ID is still missing, prompt user input
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        print_message "Please enter your GCP project ID:" $YELLOW
        read -r PROJECT_ID
        
        if [ -z "$PROJECT_ID" ]; then
            print_message "Error: project ID is required" $RED
            exit 1
        fi
    fi
    
    # Set default config variables (can be overridden by environment variables)
    SERVICE_NAME="${SERVICE_NAME:-fyp-mrsteam-web}"
    REGION="${REGION:-asia-east1}"
    
    print_message "Setting GCP project: $PROJECT_ID" $BLUE
    print_message "Service name: $SERVICE_NAME" $BLUE
    print_message "Deploy region: $REGION" $BLUE
    
    gcloud config set project "$PROJECT_ID"
    
    # Enable required APIs
    print_message "Enabling required GCP APIs..." $BLUE
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable containerregistry.googleapis.com
}

# Build and deploy
build_and_deploy() {
    print_message "Starting build and deployment..." $BLUE
    
    # Build and deploy using Cloud Build
    if gcloud builds submit --config=cloudbuild.yaml .; then
        print_message "✓ Build completed!" $GREEN
    else
        print_message "Error: build failed" $RED
        exit 1
    fi
    
    print_message "Waiting for service deployment..." $YELLOW
    sleep 10  # Wait for deployment to complete
    
    # Dynamically fetch service URL
    print_message "Fetching service URL..." $BLUE
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')
    
    if [ -n "$SERVICE_URL" ]; then
        print_message "✓ Deployment completed!" $GREEN
        print_message "Your app is deployed at: $SERVICE_URL" $GREEN
        
        # Save URL to file for later use
        echo "$SERVICE_URL" > .deployment-url
        print_message "Service URL saved to .deployment-url" $BLUE
    else
        print_message "Warning: unable to fetch service URL, check deployment status" $YELLOW
        print_message "You can check manually: gcloud run services describe $SERVICE_NAME --region $REGION" $YELLOW
    fi
}

# Local testing
local_test() {
    print_message "Running local test..." $BLUE
    
    # Build Docker image
    docker build -t fyp-mrsteam-web-local .
    
    print_message "Starting local container (port 8080)..." $BLUE
    docker run -p 8080:8080 fyp-mrsteam-web-local &
    
    print_message "Local test server started: http://localhost:8080" $GREEN
    print_message "Press Ctrl+C to stop the server" $YELLOW
}

# Get service URL
get_service_url() {
    # Set default config variables (if not set)
    SERVICE_NAME="${SERVICE_NAME:-fyp-mrsteam-web}"
    REGION="${REGION:-asia-east1}"
    
    print_message "Fetching service URL..." $BLUE
    print_message "Service name: $SERVICE_NAME" $BLUE
    print_message "Region: $REGION" $BLUE
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)' 2>/dev/null)
    
    if [ -n "$SERVICE_URL" ]; then
        print_message "Service URL: $SERVICE_URL" $GREEN
        echo "$SERVICE_URL" > .deployment-url
        print_message "URL saved to .deployment-url" $BLUE
    else
        print_message "Error: unable to find service or fetch URL" $RED
        print_message "Please confirm service name and region are correct" $YELLOW
        print_message "Available services:" $BLUE
        gcloud run services list --region=$REGION
        exit 1
    fi
}

# Clean resources
cleanup() {
    print_message "Cleaning local Docker image..." $BLUE
    docker rmi fyp-mrsteam-web-local 2>/dev/null || true
    print_message "✓ Cleanup completed" $GREEN
}

# Main function
main() {
    print_message "=== FYP MrSteam Web Deployment Tool ===" $BLUE
    
    case "${1:-deploy}" in
        "test")
            check_requirements
            local_test
            ;;
        "deploy")
            check_requirements
            setup_project
            build_and_deploy
            ;;
        "url")
            check_requirements
            get_service_url
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "Usage:"
            echo "  $0 deploy   - Deploy to GCP (default)"
            echo "  $0 test     - Local test"
            echo "  $0 url      - Get deployed service URL"
            echo "  $0 cleanup  - Clean local resources"
            echo "  $0 help     - Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  SERVICE_NAME - Service name (default: fyp-mrsteam-web)"
            echo "  REGION       - Deploy region (default: asia-east1)"
            echo "  PROJECT_ID   - GCP project ID"
            echo ""
            echo "Examples:"
            echo "  SERVICE_NAME=my-app REGION=us-central1 $0 deploy"
            echo "  SERVICE_NAME=my-app REGION=us-central1 $0 url"
            ;;
        *)
            print_message "Unknown command: $1" $RED
            print_message "Use '$0 help' to see available commands" $YELLOW
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
