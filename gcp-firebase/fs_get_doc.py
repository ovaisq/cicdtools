#!/usr/bin/env python3
"""
Get all users for a given org.
Store the output in a comma separated csv
"""

import ast
import csv
import firebase_admin
import json
import random
import time

from firebase_admin import credentials
from pprint import pprint
from firebase_admin import firestore
from random import randrange

#
# Service Account Key
#   https://console.cloud.google.com/iam-admin/serviceaccounts/details/xxxxxxxxxxxxxxxxx/keys?authuser=0&project=company-mobile
#   xxxxxxxxxxxxxxxxxxxxxxxxxx
#
cred_json = '/Users/username/Downloads/prod-company-mobile-firebase-adminsdk-xxxxx-xxxxx.json' # prod
# cred_json = '/Users/username/Downloads/stage1-company-local-dev-xxxxx-xxxxx.json' # stage1
# cred_json = '/Users/username/Downloads/company-prod-canada-xxxxxxxxx.json' # prod-canada

cred = credentials.Certificate(cred_json)
firebase_admin.initialize_app(cred)
db = firestore.client()
src_doc_id = 'xxxxxxxxXXXXX'
source_user_doc_data = db.collection('users').document(src_doc_id).get().to_dict()
user_doc_collections = db.collection('users').document(src_doc_id).collections()
actions_doc_collections = db.collection('users').document(src_doc_id).collection('actions')
orig_user_doc_data = db.collection('users').document(src_doc_id).get().to_dict()


for i in actions_doc_collections.stream():
    if 'Risk' in i.id:
        print("******")
        file_name = i.id+'.doc' 
        file_dict = json.loads(json.dumps(str(i.to_dict())))
        f = open(file_name, 'w')
        f.write(file_dict)
        f.close()
        pprint (file_name)
        print("******")
