# Alternate sensor profile: DHT22 (temperature + humidity) on GPIO4, instead
# of the DS18B20 1-Wire sensor used by src/main.py. Not built into the
# production Docker image - kept here as a documented reference for sites
# that use a different sensor. Install edge/app/requirements-dht22.txt to run
# it standalone.
import os
import time
import board
import adafruit_dht
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

INFLUX_URL = os.getenv('INFLUX_URL')
INFLUX_TOKEN = os.getenv('INFLUX_TOKEN')
INFLUX_ORG = os.getenv('INFLUX_ORG')
INFLUX_BUCKET = os.getenv('INFLUX_BUCKET')
SUCURSAL_ID = os.getenv('SUCURSAL_ID', 'Raspberry_Sin_Nombre')

try:
    sensor = adafruit_dht.DHT22(board.D4)
    print(f"[INIT] DHT22 sensor detected on GPIO4. Starting: {SUCURSAL_ID}")
except Exception as e:
    print(f"Fatal error initializing sensor: {e}")
    sensor = None

client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
write_api = client.write_api(write_options=SYNCHRONOUS)

print("--- Starting monitoring loop ---")

while True:
    try:
        temp = sensor.temperature
        hum = sensor.humidity

        if temp is None or hum is None:
            print("Read failed, retrying...")
            time.sleep(2)
            continue

        p = Point("clima_site") \
            .tag("sucursal", SUCURSAL_ID) \
            .field("temperatura", temp) \
            .field("humedad", hum)

        write_api.write(bucket=INFLUX_BUCKET, org=INFLUX_ORG, record=p)
        print(f"[{SUCURSAL_ID}] T: {temp:.1f}C | H: {hum:.1f}% -> sent to InfluxDB")

    except RuntimeError as error:
        # Transient sensor read errors are common and safe to retry
        print(f"Read error (retrying): {error.args[0]}")
        time.sleep(2.0)
        continue
    except Exception as error:
        print(f"General error: {error}")
        sensor.exit()
        raise error

    time.sleep(10)
