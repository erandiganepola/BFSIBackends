import ballerina/http;
import ballerina/io;

string fraudDetailsFile = "./fraudDetails.json";

service /frm on new http:Listener(9096) {
    resource function post validate(@http:Payload json fraudDetailsRequest) returns json|error {

        json|io:Error fraudDetails = io:fileReadJson(fraudDetailsFile);

        if fraudDetails is json[] {
            string merchantIdFromRequest = (check fraudDetailsRequest.merchant_id).toString();

            foreach var item in fraudDetails {
                if (item is json) {
                    string merchantIdFromDataSet = (check item.merchant_id).toString();
                    if (merchantIdFromDataSet == merchantIdFromRequest) {
                        json message;
                        if((check item.status).toString() == "approved"){
                            message = {
                                "message": "Transaction successfully approved. No fraudulent activity detected."
                            };
                        }else{
                            message = {
                                "message": "Transaction declined. High-risk indicators detected."
                            };
                        }
                        
                        json|error response = item.mergeJson(message);

                        return response;
                    }
                }
            }
            return error("Invalid merchant Id");
        }

    }
}
