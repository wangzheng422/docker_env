"""
Performance test script for Keycloak authentication services.

This module simulates high-volume authentication load against a Keycloak server
by generating concurrent token requests from multiple simulated users. It measures
key performance metrics including:
- Success/failure rates
- Average response times
- Request throughput

Features:
- Multi-threaded request generation using ThreadPoolExecutor
- Configurable number of simulated users and concurrent threads
- Real-time metrics reporting (per-second and per-minute intervals)
- Prometheus integration for metrics collection and visualization
- Environment variable configuration for sensitive parameters (CLIENT_SECRET)

The script is designed for performance testing, capacity planning, and
identifying bottlenecks in Keycloak deployments under load conditions.
"""
import os
import time
import threading
from concurrent.futures import ThreadPoolExecutor
import requests
from prometheus_client import start_http_server, Counter, Gauge

# CLIENT_SECRET = "hiZJdnJCCu0WXDhCVDWoyLix5bcWuYxq"

# Attempt to retrieve CLIENT_SECRET from environment variables
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")

# Get configuration from environment variables with defaults
num_users = int(os.environ.get("NUM_USERS", 50000))
num_threads = int(os.environ.get("NUM_THREADS", 10))

TARGET_URL = "http://example-kc-service:8080/realms/performance/protocol/openid-connect/token"
HEADERS = {"Content-Type": "application/x-www-form-urlencoded"}

success_count = 0
failure_count = 0
total_time = 0
lock = threading.Lock()

# Prometheus metrics
success_metric = Counter('wzh_success_count', 'Number of successful requests')
failure_metric = Counter('wzh_failure_count', 'Number of failed requests')
avg_time_sec_metric = Gauge('wzh_avg_time_sec', 'Average time per request per second')
avg_time_min_metric = Gauge('wzh_avg_time_min', 'Average time per request per minute')
success_rate_sec_metric = Gauge('wzh_success_rate_sec', 'Success rate per second')
success_rate_min_metric = Gauge('wzh_success_rate_min', 'Success rate per minute')

def make_request(start, end):
    global success_count, failure_count, total_time
    while True:
        for i in range(start, end):
            username = f"user-{i:05d}"
            data = {
                "client_id": "performance",
                "client_secret": CLIENT_SECRET,
                "username": username,
                "password": "password",
                "grant_type": "password"
            }
            start_time = time.time()
            try:
                response = requests.post(TARGET_URL, headers=HEADERS, data=data)
                elapsed_time = time.time() - start_time
                with lock:
                    total_time += elapsed_time
                    if response.status_code == 200:
                        success_count += 1
                        success_metric.inc()
                    else:
                        failure_count += 1
                        failure_metric.inc()
                        print(f"Error for user {username}: {response.status_code} {response.text}")
            except requests.RequestException as e:
                with lock:
                    failure_count += 1
                    failure_metric.inc()
                    print(f"RequestException for user {username}: {e}")

def print_summary():
    global success_count, failure_count, total_time
    while True:
        time.sleep(60)
        with lock:
            total_requests = success_count + failure_count
            success_rate = (success_count / total_requests) * 100 if total_requests > 0 else 0
            avg_time = total_time / total_requests if total_requests > 0 else 0
            avg_time_min_metric.set(avg_time)
            success_rate_min_metric.set(success_rate)
            
            # Copy values for printing outside lock
            print_success = success_count
            print_failure = failure_count
            print_success_rate = success_rate
            print_avg_time = avg_time
            
            success_count = 0
            failure_count = 0
            total_time = 0
            
        print(f"Summary (last minute): Success: {print_success}, Failure: {print_failure}, Success Rate: {print_success_rate:.2f}%, Avg Time: {print_avg_time:.2f}s")

def print_secondly_summary():
    global success_count, failure_count, total_time
    while True:
        time.sleep(1)
        with lock:
            total_requests = success_count + failure_count
            success_rate = (success_count / total_requests) * 100 if total_requests > 0 else 0
            avg_time = total_time / total_requests if total_requests > 0 else 0
            avg_time_sec_metric.set(avg_time)
            success_rate_sec_metric.set(success_rate)
        print(f"Second Summary: Success: {success_count}, Failure: {failure_count}, Success Rate: {success_rate:.2f}%, Avg Time: {avg_time:.2f}s")

if __name__ == "__main__":
    # Start Prometheus metrics server
    start_http_server(8000)

    summary_thread = threading.Thread(target=print_summary, daemon=True)
    summary_thread.start()

    secondly_summary_thread = threading.Thread(target=print_secondly_summary, daemon=True)
    secondly_summary_thread.start()

    users_per_thread = num_users // num_threads

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        for i in range(num_threads):
            start = i * users_per_thread + 1
            end = (i + 1) * users_per_thread + 1
            executor.submit(make_request, start, end)

    # Keep the main thread running indefinitely
    while True:
        time.sleep(1)
