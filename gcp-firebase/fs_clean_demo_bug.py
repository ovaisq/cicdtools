#!/usr/bin/env python3
"""Get all actions docs for a given org id and 

Requires:
    1. A GCP Service Account key with appropriate permissions
    2. An valid Company Org ID

e.g. ./fs_users_in_org.py --cred-json xxxxxx.json --org-id ZQO3tY6eMPV1NsJUmncI
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

    arg_parser = argparse.ArgumentParser(description="Get list of a given Org and save in CSV")
    arg_parser.add_argument (
                             '--org-id'
                             , dest='org_id'
                             , action='store'
                             , required=True
                             , default=''
                             , help="An Org ID [e.g. NQO35YIeMPV1NsJCmncWi].\n"
                                    "A single value, or a comma separated list"
                            )
    arg_parser.add_argument (
                             '--cred-json'
                             , dest='fs_cred_json'
                             , action='store'
                             , required=True
                             , default=''
                             , help="GCP Service Account Key json file"
                            )

    args = arg_parser.parse_args()
    org_id = args.org_id

    docids = [] #list of doc ids - this is printed at the end

    fs_cred_json = args.fs_cred_json
    db = fstools(fs_cred_json)
    #for a given collection fetch a single doc as json
    org = db.getdocbyidincoll('orgs',org_id)
    # if org exists
    if org != None:

        # get org name
        org_name = org['name']

        print ('Getting a list of users for' + '\t[Org Name: ' + org_name + ']' + '\t[Org ID: ' + org_id + ']')

        #get docs of collection name users
        users_ref = db.getdocsincoll('users','orgId',org_id)
        user_docs = users_ref.stream()
        # for user_doc in user_docs:
        #    if 'demoPowerStanceDeepDiveDay' in user_doc.id:
        #        print (user_doc.id)

        #get docs of mobileNotifications
        m_notifications_ref = db.getdocsincoll('mobileNotifications','orgId',org_id)
        m_notifications_docs = m_notifications_ref.stream()

        #get docs of orgConfig
        org_configs_ref = db.getdocsincoll('orgConfigs','org_id',org_id)
        org_configs_docs = org_configs_ref.stream()

        #get docs of workflows
        workflows_ref = db.getdocsincoll('workflows','orgId',org_id)
        workflows_docs = workflows_ref.stream()

        #get docs of trendAggregates
        trendaggs_ref = db.getdocsincoll('trendAggregates','orgId',org_id)
        trendaggs_docs = trendaggs_ref.stream()

        #get docs of trendEvents
        trendevents_ref = db.getdocsincoll('trendEvents','orgId',org_id)
        trendevents_docs = trendevents_ref.stream()

        counter = 0
        for m_n_doc in m_notifications_docs:
            counter = counter + 1
            if counter > 100:
                sleepfor = randrange(1,10)
                print ('Sleeping for ' + str(sleepfor) + ' seconds') 
                time.sleep(sleepfor)
                counter = 0
            #print (m_n_doc.id)
            print (str(counter) + ': Deleting mobileNotification '+m_n_doc.id+' for ORG '+org_name)
            db.del_m_notifications_doc(m_n_doc.id)

        for user_doc in user_docs:
            history_doc_collections = db.gethistorycol(user_doc.id, 'users')
            actions_doc_collections = db.getactionscol(user_doc.id, 'users')
            counter = 0
            for stuff in actions_doc_collections.stream():
                counter = counter + 1
                if counter > 100:
                    sleepfor = randrange(1,10)
                    print ('Sleeping for ' + str(sleepfor) + ' seconds') 
                    time.sleep(sleepfor)
                    counter = 0
                #print (user_doc.id)
                print (str(counter) + ': Deleting action '+stuff.id+' for ORG '+org_name)
                db.deluseractionsdoc(user_doc.id, stuff.id)
            counter = 0
            for history_doc in history_doc_collections.stream():
                counter = counter + 1
                if counter > 100:
                    sleepfor = randrange(1,10)
                    print ('Sleeping for ' + str(sleepfor) + ' seconds') 
                    time.sleep(sleepfor)
                    counter = 0
                #print (user_doc.id)
                print (str(counter) + ': Deleting history '+history_doc.id+' for ORG '+org_name)
                db.deluserhistorydoc(user_doc.id, history_doc.id)
            print ('Deleting user doc '+user_doc.id+' for ORG '+org_name)
            db.deluserdoc(user_doc.id)
        counter = 0
        for workflow_doc in workflows_docs:
            counter = counter + 1
            if counter > 100:
                sleepfor = randrange(1,10)
                print ('Sleeping for ' + str(sleepfor) + ' seconds') 
                time.sleep(sleepfor)
                counter = 0
            print (str(counter) + ': Deleting workflow '+workflow_doc.id+' for ORG '+org_name)
            db.delworkflowdoc(workflow_doc.id)

        for org_config_doc in org_configs_docs:
            print ('Deleting orgConfigs '+org_config_doc.id+' for ORG '+org_name)
            db.del_org_configs_doc(org_config_doc.id)

        counter = 0
        for trendagg_doc in trendaggs_docs:
            counter = counter + 1
            if counter > 100:
                sleepfor = randrange(1,10)
                print ('Sleeping for ' + str(sleepfor) + ' seconds') 
                time.sleep(sleepfor)
                counter = 0
            print (str(counter) + ': Deleting trendAggregates '+trendagg_doc.id+' for ORG '+org_name)
            db.del_trendagg_doc(trendagg_doc.id)

        counter = 0
        for trendevent_doc in trendevents_docs:
            counter = counter + 1
            if counter > 100:
                sleepfor = randrange(1,10)
                print ('Sleeping for ' + str(sleepfor) + ' seconds') 
                time.sleep(sleepfor)
                counter = 0
            print (str(counter) + ': Deleting trendEvents '+trendevent_doc.id+' for ORG '+org_name)
            db.del_trendevent_doc(trendevent_doc.id)

        print ('Deleting ORG '+org_id+' for ORG '+org_name)
        db.delorgdoc(org_id)
    else:
        print ('No users found for Org ID',org_id)
    
if __name__ == "__main__":
    main()
