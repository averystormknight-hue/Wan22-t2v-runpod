import argparse
import base64
import json
import os
import sys
import time
import requests

def encode_image(image_path):
    if image_path.startswith("http"):
        return image_path
    
    with open(image_path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("utf-8")

def main():
    parser = argparse.ArgumentParser(description="Wan2.2 T2V Client")
    parser.add_argument("--url", required=True, help="RunPod Endpoint URL")
    parser.add_argument("--key", help="RunPod API Key", default=os.getenv("RUNPOD_API_KEY"))
    parser.add_argument("--prompt", required=True, help="Positive prompt")
    parser.add_argument("--negative", default="blurry, low quality, distorted", help="Negative prompt")
    parser.add_argument("--image", help="Input image path or URL")
    parser.add_argument("--width", type=int, default=480)
    parser.add_argument("--height", type=int, default=832)
    parser.add_argument("--length", type=int, default=81)
    parser.add_argument("--steps", type=int, default=25)
    parser.add_argument("--cfg", type=float, default=2.0)
    parser.add_argument("--output", default="output.mp4", help="Output filename")
    
    args = parser.parse_args()

    if not args.key:
        print("Error: --key or RUNPOD_API_KEY env var is required")
        sys.exit(1)

    payload = {
        "input": {
            "prompt": args.prompt,
            "negative_prompt": args.negative,
            "media_settings": {
                "width": args.width,
                "height": args.height,
                "length": args.length,
                "steps": args.steps,
                "cfg": args.cfg
            }
        }
    }

    if args.image:
        if args.image.startswith("http"):
            payload["input"]["image_url"] = args.image
        else:
            payload["input"]["image_base64"] = encode_image(args.image)

    headers = {
        "Authorization": f"Bearer {args.key}",
        "Content-Type": "application/json"
    }

    print(f"Sending request to {args.url}...")
    try:
        # Initial run request
        resp = requests.post(f"{args.url}/run", json=payload, headers=headers)
        resp.raise_for_status()
        job_id = resp.json()["id"]
        print(f"Job ID: {job_id}")

        # Polling
        while True:
            status_resp = requests.get(f"{args.url}/status/{job_id}", headers=headers)
            status_resp.raise_for_status()
            status_data = status_resp.json()
            status = status_data["status"]
            
            if status == "COMPLETED":
                output = status_data["output"]
                if "error" in output:
                    print(f"Job failed with error: {output['error']}")
                    sys.exit(1)
                
                video_data = output["video"]
                # data:video/mp4;base64,....
                b64_str = video_data.split(",")[1]
                with open(args.output, "wb") as f:
                    f.write(base64.b64decode(b64_str))
                print(f"Saved video to {args.output}")
                break
            
            elif status == "FAILED":
                print("Job failed.")
                sys.exit(1)
            
            else:
                print(f"Status: {status}...")
                time.sleep(2)

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
