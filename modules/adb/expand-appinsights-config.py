#!/usr/bin/env python3

import argparse
import json
import sys


parser = argparse.ArgumentParser("expand-appinsights-config.py")
parser.add_argument("-w", "--max-workers", type=int, required=True)
parser.add_argument("infile", nargs="?", type=argparse.FileType("r"), default=sys.stdin)
parser.add_argument(
    "outfile", nargs="?", type=argparse.FileType("w"), default=sys.stdout
)
args = parser.parse_args()

max_workers = args.max_workers

data = json.load(args.infile)

jmx_metrics = data["jmxMetrics"]

new_data = []
for metric in jmx_metrics:
    if metric["objectName"].startswith("metrics:name=spark.0."):
        for d in range(max_workers):
            new_metric = metric.copy()
            new_metric[
                "objectName"
            ] = f"metrics:name=spark.{d}.{new_metric['objectName'].removeprefix('metrics:name=spark.0.')}"
            new_data.append(new_metric)
    else:
        new_data.append(metric)

data["jmxMetrics"] = new_data

json.dump(data, args.outfile, indent=4)
