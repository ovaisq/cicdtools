#!/usr/bin/env python3
"""Get Global Workflows

Requires:
    1. A GCP Service Account key with appropriate permissions

e.g. ./fs_get_workflows.py --cred-json xxxxxx.json
"""

import argparse
import csv
import firebase_admin
import json
import time

from firebase_admin import credentials
from firebase_admin import firestore
from fstools import FsTools as fstools #requires fstools.py
from random import randrange


def main():

    arg_parser = argparse.ArgumentParser(description="Get Global Workflows List")
    arg_parser.add_argument (
                             '--cred-json'
                             , dest='cred_json'
                             , action='store'
                             , required=True
                             , default=''
                             , help="GCP Service Account Key json file"
                            )

    args = arg_parser.parse_args()

    labels = []
    filter_out = ['Feedback', 'weekdayCheckIn', 'tos', 'onboarding', 'top', 'high', 'shout', 'follow', 'manager', 'passcode', 'Covid', 'never', 'reports', 'demo'] 

    cred_json = args.cred_json
    cred = credentials.Certificate(cred_json)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    for i in db.collection('globalWorkflows').stream():
        res = any(substring in i.id for substring in filter_out)
        if not res:
            a_doc = db.collection('globalWorkflows').document(i.id).get().to_dict()
            labels.append(a_doc['states']['main']['mobileFlow']['label'])
    grouped_unique_ordered_labels = list (dict.fromkeys(labels))
    print (labels)
    print (grouped_unique_ordered_labels)

if __name__ == '__main__':
    main()
