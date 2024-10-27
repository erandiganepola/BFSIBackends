import ballerina/http;
import ballerina/io;

string userDetailsFile = "./userDetails.json";
string creditRatingFile = "./creditRating.json";
string creditCardAuthDetailsFile = "./creditCardAuthorizationDetails.json";
string creditCardDetailsFile = "./creditCardDetails.json";
string requestsFilePath = "./requests.json";

service /cbs on new http:Listener(9095) {

    resource function get hello () returns json {
        return {success: true};
    }

    resource function get users/search(string first_name, string last_name, string social_security_number) returns User|error {

        json|io:Error userDetails = io:fileReadJson(userDetailsFile);

        if userDetails is json[] {
            string name = string:'join(" ", first_name, last_name);

            foreach var item in userDetails {
                if (item is json) {
                    string socialSecurityNumberFromDataSet = (check item.social_security_number).toString();
                    string nameFromDataSet = (check item.name).toString();
                    if (socialSecurityNumberFromDataSet == social_security_number) {

                        if (nameFromDataSet == name) {
                            User user = {address: "", phone: "", name: "", customer_id: "", email: ""};

                            user.customer_id = (check item.customer_id).toString();
                            user.name = nameFromDataSet;
                            user.email = (check item.email).toString();
                            user.phone = (check item.phone).toString();
                            user.address = (check item.address).toString();

                            return user;
                        }
                    }
                }
            }
        }
        return error("Invalid User details");
    }

    resource function get credit_rating(string user_id) returns json|error {
    json|io:Error creditRatingDetails = io:fileReadJson(creditRatingFile);
    json|io:Error requestDetails = io:fileReadJson(requestsFilePath);

    if creditRatingDetails is json[] {

        foreach var item in creditRatingDetails {
            if (item is json) {
                string userIdFromDataSet = (check item.user_id).toString();
                if (userIdFromDataSet == user_id) {
                    if (requestDetails is json[]) {
                        foreach var req in requestDetails {
                            if (req is json) {
                                string userIdFromRequestDataSet = (check req.customer_id).toString();
                                if (userIdFromRequestDataSet == user_id) {
                                    json additionalProperties = {
                                        "credit_rating": (check item.credit_rating).toString()
                                    };
                                    json|error result = req.mergeJson(additionalProperties);
                                    // check io:fileWriteJson(requestsFilePath, requestDetails);
                                }
                            }
                        }
                    }
                    return item;
                }
            }
        }
        return error("Invalid User Id");
    }
}


    resource function post cc/auth(@http:Payload json creditCardDetailsRequest) returns json|error {

        json|io:Error creditCardAuthDetails = io:fileReadJson(creditCardAuthDetailsFile);
        json|io:Error creditCardDetails = io:fileReadJson(creditCardDetailsFile);

        if creditCardAuthDetails is json[] {
            string merchantIdFromRequest = (check creditCardDetailsRequest.merchant_id).toString();

            foreach var item in creditCardAuthDetails {
                if (item is json) {
                    string merchantIdFromDataSet = (check item.merchant_id).toString();
                    if (merchantIdFromDataSet == merchantIdFromRequest) {
                        json message;
                        if ((check item.status).toString() == "approved") {
                            message = {
                                "message": "Transaction approved successfully."
                            };
                        } else {
                            string merchantEmail = check getMerchantEmail(merchantIdFromRequest, creditCardDetails);
                            message = {
                                "message": "Transaction declined. Insufficient funds.",
                                "email": merchantEmail
                            };
                        }

                        json|error response = item.mergeJson(message);
                        return response;
                    }
                }
            }
            return error("Invalid transaction Id");
        }
    }

}

function getMerchantEmail(string merchantId, json|io:Error creditCardDetails) returns string|error {
    if creditCardDetails is json[] {
        foreach var item in creditCardDetails {
            if (item is json) {
                string merchantIdFromDataSet = (check item.merchant_id).toString();
                if (merchantIdFromDataSet == merchantId) {
                    return (check item.email).toString();
                }
            }
        }
    }
    return "";
}
