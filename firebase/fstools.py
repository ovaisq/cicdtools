import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore

class FsTools(object):

    def __init__(self, credjson):
        self.cred_json = credjson
        self.cred = credentials.Certificate(self.cred_json)
        firebase_admin.initialize_app(self.cred)
        self._fs_connect = firestore.client()

    def getdocbyidincoll(self, collection, docid):
        """Fetch document json data using a document ID in a collection"""
        
        self.collection = collection
        self.docid = docid
        return self._fs_connect.collection(self.collection).document(self.docid).get().to_dict()

    def getdocsincoll(self, collection, key, value):
        """Get filtered list of docs of a collection"""

        self.collection = collection
        self.key = key
        self.value = value
        return self._fs_connect.collection(self.collection).where(self.key,'==',self.value)

    def setdocdataincoll(self, collection, docid, docdata):
        """Add doc and data to a given collection"""

        self.collection = collection
        self.docid = docid
        self.docdata = docdata
        return self._fs_connect.collection(self.collection).document(self.docid).set(self.docdata)

    def getactionscol(self, doc_id, collection):
        """Get a subcollection titled actions for a given collection"""

        self.collection = collection
        self.doc_id = doc_id
        return self._fs_connect.collection(self.collection).document(self.doc_id).collection('actions')

    def gethistorycol(self, doc_id, collection):
        """Get a subcollection titled history for a given collection"""

        self.collection = collection
        self.doc_id = doc_id
        return self._fs_connect.collection(self.collection).document(self.doc_id).collection('history')

    def delorgdoc(self, org_id):
        """Delete a given document in a orgs collection"""

        self.org_id = org_id
        return self._fs_connect.collection('orgs').document(self.org_id).delete()

    def deluserdoc(self, user_id):
        """Delete a given document in a users collection"""

        self.user_id = user_id
        return self._fs_connect.collection('users').document(self.user_id).delete()

    def del_org_configs_doc(self, org_config_doc_id): 
        """Delete a given document in a orgConfigs collection"""

        self.org_config_doc_id = org_config_doc_id
        return self._fs_connect.collection('orgConfigs').document(self.org_config_doc_id).delete()

    def del_trendagg_doc(self, trendagg_doc_id): 
        """Delete a given document in a trendAggregates collection"""

        self.trendagg_doc_id = trendagg_doc_id
        return self._fs_connect.collection('trendAggregates').document(self.trendagg_doc_id).delete()

    def del_trendevent_doc(self, trendevent_doc_id): 
        """Delete a given document in a trendEvents collection"""

        self.trendevent_doc_id = trendevent_doc_id
        return self._fs_connect.collection('trendEvents').document(self.trendevent_doc_id).delete()

    def del_m_notifications_doc(self, m_n_doc_id): 
        """Delete a given document in a mobileNotification collection"""

        self.m_n_doc_id = m_n_doc_id
        return self._fs_connect.collection('mobileNotifications').document(self.m_n_doc_id).delete()

    def delworkflowdoc(self, workflow_doc_id): 
        """Delete a given document in a workflows collection"""

        self.workflow_doc_id = workflow_doc_id
        return self._fs_connect.collection('workflows').document(self.workflow_doc_id).delete()

    def deluseractionsdoc(self, user_id, actions_doc_id): 
        """Delete a given document in a sub-collection named actions"""

        self.user_id = user_id
        self.actions_doc_id = actions_doc_id
        return self._fs_connect.collection('users').document(self.user_id).collection('actions').document(self.actions_doc_id).delete()

    def deluserhistorydoc(self, user_id, history_doc_id): 
        """Delete a given document in a sub-collection named history"""

        self.user_id = user_id
        self.history_doc_id = history_doc_id
        return self._fs_connect.collection('users').document(self.user_id).collection('history').document(self.history_doc_id).delete()
