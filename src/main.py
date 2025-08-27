import os

def main():
    """Main entrypoint for the healthcare chatbot."""
    env = os.getenv("ENV", "development")
    print(f"Running Healthcare Chatbot in {env} mode...")

if __name__ == "__main__":
    main()
