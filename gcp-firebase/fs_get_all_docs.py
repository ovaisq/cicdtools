#!/usr/bin/env python3
"""
Get all users for a given org.
Store the output in a comma separated csv
"""

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
cred_json = '/Users/username/Downloads/company-mobile-firebase-adminsdk-xxxxx-xxxxx.json' # prod
# cred_json = '/Users/username/Downloads/stage1-company-local-dev-xxxxx-xxxxx.json' # stage1
# cred_json = '/Users/username/Downloads/company-prod-canada-xxxxxxxxx.json' # prod-canada

cred = credentials.Certificate(cred_json)
firebase_admin.initialize_app(cred)
db = firestore.client()
src_doc_ids = ['1QnoP7LCdSzl4VFndG1g','3oh4lGZnwc9AJqHntky0','70XIa2ZWMy826EY5QFTG','7iMC1b76lMrKSOcptJOV','9pp2oyIPy1PyX42JlhiX','JHvF156AZw0yE1N8AqK1','KiMEkpj1QBl6UFSHHgJJ','ZDLGxDCPxslINZHqGba6','oqFJguw5SVLLiwncfQNQ','qZif2p5iNIdoG4tCywEu']

doc_ids = []

['04y7X26N2vTWVddZlmSK', '0DkwVzBzEYY8hXuHtCmO', '0W0sW6lkpKuJpgbWuSjp'] 

for doc_id in doc_ids:
    src_doc_id = random.choice(src_doc_ids)
    # src_doc_id = src_doc_ids[0]
    source_user_doc_data = db.collection('users').document(src_doc_id).get().to_dict()
    user_doc_collections = db.collection('users').document(src_doc_id).collections()
    print ('Updating',doc_id,'with',src_doc_id)
    user_doc_collections = db.collection('users').document(src_doc_id).collections()
    orig_user_doc_data = db.collection('users').document(doc_id).get().to_dict()

    try:
        orig_user_doc_data |= {
                                'lastSignedIn': source_user_doc_data['lastSignedIn'],
                                'appVersion' : source_user_doc_data['appVersion'],
                                'iv' : source_user_doc_data['iv'],
                                'hasPin' : source_user_doc_data['hasPin'],
                                'deviceModel' : source_user_doc_data['deviceModel'],
                                'workflowsLastProcessedAt' : source_user_doc_data['workflowsLastProcessedAt'],
                                'id' : doc_id,
                                'deviceName': doc_id,
                                'fcmTokens': source_user_doc_data['fcmTokens'],
                                'employeePin' : source_user_doc_data['employeePin'],
                                'platform' : source_user_doc_data['platform'],
                              }
    except KeyError:
        orig_user_doc_data |= {
                                'lastSignedIn': source_user_doc_data['lastSignedIn'],
                                'appVersion' : source_user_doc_data['appVersion'],
                                'iv' : '',
                                'hasPin' : '',
                                'deviceModel' : source_user_doc_data['deviceModel'],
                                'workflowsLastProcessedAt' : source_user_doc_data['workflowsLastProcessedAt'],
                                'id' : doc_id,
                                'deviceName': doc_id,
                                'fcmTokens': source_user_doc_data['fcmTokens'],
                                'employeePin' : '',
                                'platform' : source_user_doc_data['platform'],
                              }

    print ('\t','Updating', doc_id)
    db.collection(u'users').document(doc_id).update(orig_user_doc_data)
    while (db.collection(u'users').document(doc_id).get().to_dict() != orig_user_doc_data):
        print ('Updating', doc_id)
        sleep.time(5)
    for user_doc_collection in user_doc_collections:
        for user_doc in user_doc_collection.stream():
            user_doc_id = user_doc.id
            foo = user_doc_id.split('.')
            if len(foo) > 2:
                foo[1] = doc_id 
                new_user_doc_id = '.'.join(foo)
                new_wf_id = '.'.join(foo[:-1])
            else:
                new_user_doc_id = user_doc.id
                new_wf_id = user_doc.to_dict()['workflowInstanceId']
            user_doc_data = user_doc.to_dict()
            #pprint(user_doc_data)
            #print ('*************        ')
            user_doc_data |= {'context': {
                                          'employee':{
                                                      'id':doc_id, 
                                                      'managerId': orig_user_doc_data['managerId'],
                                                      'appVersion': orig_user_doc_data['appVersion'],
                                                      'companyName':  orig_user_doc_data['companyName'],
                                                      'deactivatedAt': '',
                                                      'debug': orig_user_doc_data['debug'],
                                                      'deviceModel': orig_user_doc_data['deviceModel'],
                                                      'deviceName': orig_user_doc_data['deviceName'],
                                                      'email': orig_user_doc_data['email'],
                                                      'employeeId': orig_user_doc_data['employeeId'],
                                                      'employeePin': None,
                                                      'firstName': orig_user_doc_data['firstName'],
                                                      'fullName': orig_user_doc_data['fullName'],
                                                      'hasPin': orig_user_doc_data['hasPin'],
                                                      'inviteCode': orig_user_doc_data['inviteCode'],
                                                      'iv': orig_user_doc_data['iv'],
                                                      'jobTitle': orig_user_doc_data['jobTitle'],
                                                      'language': orig_user_doc_data['language'],
                                                      'lastName': orig_user_doc_data['lastName'],
                                                      'location': orig_user_doc_data['location'],
                                                      'manager': orig_user_doc_data['manager'],
                                                      'mdm': False,
                                                      'mobilePhone': orig_user_doc_data['mobilePhone'],
                                                      'orgId': orig_user_doc_data['orgId'],
                                                      'passwordAdmin': orig_user_doc_data['passwordAdmin'],
                                                      'platform': 'ios',
                                                      'role': orig_user_doc_data['role'],
                                                      'startDate': '2020-08-04',
                                                      'team': orig_user_doc_data['team'],
                                                      'timeZone': ''
                                                     } 
                                         },
                                        'id':new_user_doc_id,
                                        'workflowInstanceId':new_wf_id,
                             }
            #pprint(user_doc_data)
            print ('\t','Adding to',new_user_doc_id) 
            db.collection('users').document(doc_id).collection(user_doc_collection.id).document(new_user_doc_id).set(user_doc_data)
            while (db.collection('users').document(doc_id).collection(user_doc_collection.id).document(new_user_doc_id).get().to_dict() != user_doc_data):
                print ('Adding',doc_id)
                time.sleep(5)
