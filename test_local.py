import os
import sys
import json
import base64
import argparse

# Set environment variables BEFORE importing handler
# Assuming running from project root
cwd = os.getcwd()
os.environ["WORKFLOW_PATH"] = os.path.join(cwd, "workflows", "wan22_t2v_api.json")
os.environ["COMFY_INPUT_DIR"] = os.path.join(cwd, "local_input")
os.environ["COMFY_OUTPUT_DIR"] = os.path.join(cwd, "local_output")
# Ensure these directories exist
os.makedirs(os.environ["COMFY_INPUT_DIR"], exist_ok=True)
os.makedirs(os.environ["COMFY_OUTPUT_DIR"], exist_ok=True)

try:
    from handler import handler
except ImportError:
    print("Error: Could not import handler. Make sure you are in the project root.")
    sys.exit(1)

def encode_image(image_path):
    if not image_path:
        return None
    with open(image_path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("utf-8")

def main():
    parser = argparse.ArgumentParser(description="Test Handler Locally")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--image", help="Path to input image")
    parser.add_argument("--output", default="local_test_output.mp4")
    args = parser.parse_args()

    print(f"Testing handler with workflow: {os.environ['WORKFLOW_PATH']}")
    
    # Mock Job
    job = {
        "input": {
            "prompt": args.prompt,
            "image_base64": encode_image(args.image),
            "width": 480,
            "height": 832,
            "length": 81,
            "steps": 10
        }
    }

    print("Invoking handler...")
    result = handler(job)

    if "error" in result:
        print(f"Handler failed: {result['error']}")
    elif "video" in result:
        print("Success! Saving video...")
        b64_str = result["video"].split(",")[1]
        with open(args.output, "wb") as f:
            f.write(base64.b64decode(b64_str))
        print(f"Saved to {args.output}")
    else:
        print(f"Unknown result format: {result.keys()}")

if __name__ == "__main__":
    main()
