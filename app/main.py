from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()


@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Kubernetes Demo App</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 700px;
                margin: 80px auto;
                text-align: center;
            }

            h1 {
                color: #326ce5;
            }

            .box {
                padding: 30px;
                border: 1px solid #ddd;
                border-radius: 10px;
            }
        </style>
    </head>

    <body>
        <div class="box">
            <h1>Hello Kubernetes 🚀</h1>
            <p>This is my first web application.</p>
            <p>Later, this application will run inside Kubernetes.</p>
        </div>
    </body>
    </html>
    """


@app.get("/health")
def health():
    return {"status": "healthy"}
