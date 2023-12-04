#!/usr/bin/env python3
"""Add users to an org

Requires fstools.py

Eample:

> ./fs_add_user.py --cred-json srvc_act_key.json --org-id <org id>

Manager Document g84ZEOA7QVo9XFldvbea created
User Document I36ezlfYbkvq7dVCr5n2 created

"""

import argparse
import datetime
import json
import random

from fstools import FsTools as fstools #requires fstools.py

def rand_employee_id():
    """Generate random employee id - int or alphanumeric
        
    This is the employee id for the kiosk mode
    """

    variations = 3
    # never 3 only 1 or 2
    num = random.randrange(1, variations)
    if num == 1:
        return rand_alpha_nums(6)
    if num == 2:
        return str(random.randrange(100000,999999))

def rand_alpha_nums(numchars):
    """Generate random alphanumeric string of numchars"""

    alphanum_str = ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
    return ''.join(random.sample(alphanum_str,numchars))

def set_demographics(role, companyname, orgid, manager, managerid):
    """Generate data json object for a user document

    Requires:
        role - employee role (manager or employee)
        compnayName - company organization name
        orgId - company organization id
        manager - manager's full name
        managerId - this usually is the 20 char alphanum
    """

    team = 'QA'
    location = 'California'

    #json object template
    user_json = {
                 'companyName': '', 
                 'deactivatedAt': '', 
                 'debug': False, 
                 'email': '',
                 'employeeId': '', 
                 'employeePin': 'BbBCBA==', 
                 'externalId': '', 
                 'fcmTokens': [], 
                 'firstName': '', 
                 'fullName': '', 
                 'inviteCode': '', 
                 'jobTitle': '', 
                 'language': '', 
                 'lastName': '', 
                 'location': '', 
                 'manager': '', 
                 'managerId': '', 
                 'mdm': False, 
                 'mobilePhone': '', 
                 'orgId': '', 
                 'passwordAdmin': False, 
                 'platform': '', 
                 'role': '', 
                 'startDate': '', 
                 'team': '', 
                 'timeZone': '', 
                }

    if role == 'manager':
        managerId = ''
        manager = ''
        jobTitle = 'Manager'
    if role == 'employee':
        managerId = managerid
        jobTitle = 'Employee'

    firstName = 'QA_F_'+rand_alpha_nums(8)
    lastName = 'QA_L_'+rand_alpha_nums(8)
    fullName = firstName + ' ' + lastName

    #prepare demographic data
    demographics = {
                   'companyName' : companyname,
                   'employeeId' : rand_employee_id(),
                   'firstName' : firstName,
                   'lastName' : lastName,
                   'fullName' : fullName,
                   'jobTitle' : jobTitle,
                   'location' : location,
                   'manager': manager, 
                   'managerId': managerId, 
                   'mobilePhone' : '+1',
                   'orgId' : orgid,
                   'role' : role,
                   'team' : team,
                   }

    #update json data template with values
    user_json.update(demographics)

    return user_json

def main():

    arg_parser = argparse.ArgumentParser(description="Add a user to a given organization")
    arg_parser.add_argument (
                             '--org-id'
                             , dest='org_id'
                             , action='store'
                             , required=True
                             , default=''
                             , help="An Org ID [e.g. NQO35YIeMPV1NsJCmncWi]."
                            )
    arg_parser.add_argument (
                             '--cred-json'
                             , dest='fs_cred_json'
                             , action='store'
                             , required=True
                             , default=''
                             , help="GCP Service Account Key json file"
                            )
    arg_parser.add_argument (
                             '--num-users'
                             , dest='num_users'
                             , action='store'
                             , required=False
                             , default=1
                             , help="Number of users to add. Note this is num employees + 1 manager."
                            )

    args = arg_parser.parse_args()
    org_id = args.org_id

    fs_cred_json = args.fs_cred_json
    db = fstools(fs_cred_json) #firestore admin api

    #for a given collection fetch a single doc as json
    org = db.getdocbyidincoll('orgs',org_id)
    companyName = org['name']
    
    #document id of a user - manager
    doc_id = rand_alpha_nums(20)
    role = 'manager'

    #build user data object for document - this is a python dictionary
    user_dict = set_demographics(role, companyName, org_id,'','')

    #set up manager info for employee user
    manager = user_dict['fullName']
    managerId = doc_id

    db.setdocdataincoll('users',doc_id,user_dict) #firestore admin api

    print ('Manager Document', doc_id, 'created')

    #iterate over user creation
    num_employees = args.num_users
    for i in range(1,num_employees+1):
        role = 'employee'
        #document id of a user - employee
        doc_id = rand_alpha_nums(20)
        user_dict = set_demographics(role, companyName, org_id,manager,managerId)
        db.setdocdataincoll('users',doc_id,user_dict) #firestore admin api
        print ('User Document', doc_id, 'created')

if __name__ == "__main__":
    main()
