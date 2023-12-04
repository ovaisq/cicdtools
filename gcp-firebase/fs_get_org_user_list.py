#!/usr/bin/env python3
"""Get all users for a given org id and save in a tab separated CSVi

Requires:
    1. A GCP Service Account key with appropriate permissions
    2. An valid Company Org ID

e.g. ./fs_users_in_org.py --cred-json xxxxxx.json --org-id ZQO3tY6eMPV1NsJUmncI
"""

import argparse
import csv
import json
import time

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
        epoch = str(int(time.time())) #epoch 
        csv_filename = epoch + '_' + org_id + '_' + 'users.csv' #uniquish name for the csv

        with open(csv_filename, 'w', newline='') as csvfile:

            fieldnames = [
                          'Org_Name',
                          'User_Id',
                          'User_FirstName',
                          'User_LastName',
                          'User_MobilePhone',
                          'User_Email',
                          'Employee_Id',
                          'Manager_Id',
                          'Manager',
                          'Status'
                         ]

            #excel friendly tab delimited csv
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames, dialect='excel', delimiter='\t', quoting=csv.QUOTE_ALL)
            writer.writeheader() #add header

            # get org name
            org_name = org['name']

            print ('Getting a list of users for' + '\t[Org Name: ' + org_name + ']' + '\t[Org ID: ' + org_id + ']')

            #get docs of collection name users
            users_ref = db.getdocsincoll('users','orgId',org_id)
            user_docs = users_ref.stream()

            for user_doc in user_docs:
                try:
                    #add to the csv file - this is for a user that has logged in
                    writer.writerow({
                                     'Org_Name' : org_name,
                                     'User_Id'  : user_doc.to_dict()['id'],
                                     'User_LastName' : user_doc.to_dict()['lastName'],
                                     'User_MobilePhone' : user_doc.to_dict()['mobilePhone'],
                                     'User_Email' : user_doc.to_dict()['email'],
                                     'Employee_Id' : user_doc.to_dict()['employeeId'],
                                     'Manager_Id' : user_doc.to_dict()['managerId'],
                                     'Manager' : user_doc.to_dict()['manager'],
                                     'Status' : 'user_has_logged_in',
                                    })
                    docids.append(user_doc.id) #use document id itself
                except KeyError:
                    #add to the csv file - a user that hasn't logged in
                    writer.writerow({
                                     'Org_Name' : org_name,
                                     'User_Id'  : user_doc.id,
                                     'User_LastName' : user_doc.to_dict()['lastName'],
                                     'User_MobilePhone' : user_doc.to_dict()['mobilePhone'],
                                     'User_Email' : user_doc.to_dict()['email'],
                                     'Employee_Id' : '',
                                     'Manager_Id' : user_doc.to_dict()['managerId'],
                                     'Manager' : user_doc.to_dict()['manager'],
                                     'Status' : 'user_never_logged_in',
                                    })
                    docids.append(user_doc.id) #printed at the end of script

        #use this as a list of ids to be consumed by other tools
        # print (docids)
        print (len(docids), 'users in the org') 
        # print (csv_filename)
    else:
        print ('No users found for Org ID',org_id)
    

if __name__ == "__main__":
    main()
