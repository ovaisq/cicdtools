#!/usr/bin/env python3
"""
Delete a user document from a collection of users
"""

import csv
import firebase_admin
import json

from firebase_admin import credentials
from firebase_admin import firestore

#
# Service Account Key
#   https://console.cloud.google.com/iam-admin/serviceaccounts/details/xxxxxxxxxxxxxxxxx/keys?authuser=0&project=company-mobile
#   xxxxxxxxxxxxxxxxxxxxxxxxxx
#
# cred_json = '/Users/username/Downloads/prod-company-mobile-firebase-adminsdk-xxxxx-xxxxx.json' #prod
cred_json = '/Users/username/Downloads/stage1-company-local-dev-xxxxx-xxxxx.json' # stage1

cred = credentials.Certificate(cred_json)
firebase_admin.initialize_app(cred)
db = firestore.client()

# TODO: use CLI args
org_id = 'NQO35YIeMPV1NsJCmncW'
user_ids = []
user_ids = ['02ftdZNORPc36GKgIEWy', '03Lik5shyZcfVzEAUWD2', '04XEQRHSsxa7b9geD1yT']


# get user docs
users_ref = db.collection(u'users').where(u'orgId','==',org_id)
user_docs = users_ref.stream()

for user_doc in user_docs:
    if user_doc.to_dict()['lastName'] in user_ids:
            print ('Deleting by Last Name',user_doc.to_dict()['lastName'])
            db.collection(u'users').document(user_doc.id).delete()
            print ('\t',user_doc.to_dict()['lastName'], user_doc.id,'DELETED')
    if user_doc.id in user_ids:
            print ('Deleting User ID', user_doc.id)
            db.collection(u'users').document(user_doc.id).delete()
            print ('\t',user_doc.id,'DELETED')
