#!/usr/bin/env python3
import boto3
import random
import time
import argparse
from datetime import datetime

class ChaosCostExperiment:
    """
    Chaos engineering for cost resilience
    Deliberately creates cost events to test auto-remediation
    """
    
    def __init__(self, experiment_name="default"):
        self.experiment_name = experiment_name
        self.ec2 = boto3.client('ec2')
        self.dry_run = False
        
    def _create_instance_spike(self, duration_minutes=10, dry_run=False):
        """Launch temporary instances to create cost spike"""
        if dry_run:
            print(f"🔮 DRY RUN: Would launch instances for {duration_minutes} minutes")
            return {'experiment': 'instance_spike', 'dry_run': True}
        
        instance_types = ['t2.micro', 't2.small', 't3.micro']
        count = random.randint(3, 8)
        
        print(f"🚀 Launching {count} instances for {duration_minutes} minutes...")
        
        try:
            response = self.ec2.run_instances(
                ImageId='ami-0c55b159cbfafe1f0',  # Amazon Linux 2
                InstanceType=random.choice(instance_types),
                MinCount=count,
                MaxCount=count,
                TagSpecifications=[{
                    'ResourceType': 'instance',
                    'Tags': [
                        {'Key': 'Name', 'Value': f'chaos-experiment-{self.experiment_name}'},
                        {'Key': 'chaos-test', 'Value': 'true'},
                        {'Key': 'auto-terminate', 'Value': str(duration_minutes)}
                    ]
                }]
            )
            
            instance_ids = [i['InstanceId'] for i in response['Instances']]
            print(f"✅ Launched instances: {instance_ids}")
            
            # Schedule termination
            print(f"⏰ Waiting {duration_minutes} minutes...")
            time.sleep(duration_minutes * 60)
            
            self.ec2.terminate_instances(InstanceIds=instance_ids)
            print(f"✅ Terminated chaos instances after {duration_minutes}m")
            
            return {
                'experiment': 'instance_spike',
                'instances_launched': len(instance_ids),
                'duration_minutes': duration_minutes,
                'status': 'completed'
            }
        except Exception as e:
            print(f"❌ Error: {e}")
            return {'experiment': 'instance_spike', 'error': str(e)}
    
    def run_experiment(self, experiment_type, dry_run=False, **kwargs):
        """Run a specific chaos experiment"""
        print(f"🎯 Starting chaos experiment: {experiment_type}")
        
        if experiment_type == 'instance_spike':
            return self._create_instance_spike(**kwargs, dry_run=dry_run)
        else:
            return {'error': f'Unknown experiment type: {experiment_type}'}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run chaos cost experiments')
    parser.add_argument('--type', default='instance_spike', help='Experiment type')
    parser.add_argument('--duration', type=int, default=5, help='Duration in minutes')
    parser.add_argument('--dry-run', action='store_true', help='Dry run (no actual resources)')
    
    args = parser.parse_args()
    
    experiment = ChaosCostExperiment(f"test-{datetime.now().strftime('%Y%m%d-%H%M%S')}")
    result = experiment.run_experiment(
        args.type, 
        duration_minutes=args.duration,
        dry_run=args.dry_run
    )
    
    print("\n📊 Experiment Result:")
    print(result)
