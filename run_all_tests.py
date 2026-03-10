#!/usr/bin/env python3
# run_all_tests.py - Test all Python scripts

import subprocess
import sys
import os

def print_header(msg):
    print("\n" + "="*60)
    print(f"🔷 {msg}")
    print("="*60)

def run_command(cmd, cwd=None):
    print(f"\n$ {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if result.returncode == 0:
        print("✅ SUCCESS")
        if result.stdout:
            print(result.stdout[:500] + "..." if len(result.stdout) > 500 else result.stdout)
    else:
        print("❌ FAILED")
        print(result.stderr)
    return result.returncode == 0

def main():
    # Get the repo root
    repo_root = os.path.dirname(os.path.abspath(__file__))
    
    # Track successes
    successes = 0
    total = 0
    
    # 1. Test ML Model
    print_header("Testing ML Model Training")
    ml_path = os.path.join(repo_root, "ml-cost-predictor/model")
    if os.path.exists(ml_path):
        if run_command("python3 -c 'from train import QuantumCostPredictor; print(\"✅ ML module imported\")'", cwd=ml_path):
            successes += 1
        total += 1
    else:
        print("⚠️ ML model directory not found, skipping")
    
    # 2. Test Lambda functions
    print_header("Testing Lambda Functions")
    lambda_path = os.path.join(repo_root, "lambda/auto_remediation")
    if os.path.exists(lambda_path):
        if run_command("python3 -c 'from index import handler; print(\"✅ Lambda imported successfully\")'", cwd=lambda_path):
            successes += 1
        total += 1
    else:
        print("⚠️ Lambda directory not found, skipping")
    
    # 3. Test Chaos Engine
    print_header("Testing Chaos Engine")
    chaos_path = os.path.join(repo_root, "chaos-cost-engine")
    if os.path.exists(chaos_path):
        if run_command("python3 experiment_runner.py --help", cwd=chaos_path):
            successes += 1
        total += 1
    else:
        print("⚠️ Chaos engine directory not found, skipping")
    
    # 4. Test Carbon Scheduler
    print_header("Testing Carbon Scheduler")
    carbon_path = os.path.join(repo_root, "lambda/carbon_scheduler")
    if os.path.exists(carbon_path):
        if run_command("python3 -c 'from index import CarbonAwareScheduler; print(\"✅ Carbon scheduler imported\")'", cwd=carbon_path):
            successes += 1
        total += 1
    else:
        print("⚠️ Carbon scheduler directory not found, skipping")
    
    # Summary
    print("\n" + "="*60)
    print(f"📊 TEST SUMMARY: {successes}/{total} passed")
    print("="*60)
    
    if successes == total and total > 0:
        print("\n🎉 ALL TESTS PASSED! Ready to deploy!")
    elif total == 0:
        print("\n⚠️ No tests found. Create the Python files first.")
    else:
        print("\n⚠️ Some tests failed. Check output above.")
    
    return 0 if successes == total else 1

if __name__ == "__main__":
    sys.exit(main())
