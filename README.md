```sh
git clone https://github.com/Okikulo/Phatry.git
cd Phatry
uv sync
# Enter the virtual environment
source .venv/bin/activate
docker-compose up -d
# Option 1: Postgres version
python postgres.py
# Option 2: MongoDB version
python mongo.py
```
