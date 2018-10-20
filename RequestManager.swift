import UIKit
import Alamofire



protocol RequestManagerDelegate {
    func onResult(result:NSMutableDictionary)
    func onFault(error:NSError)
}


class RequestManager: NSObject {

    var commandName: String!
    var tag: String!

    var delegate: RequestManagerDelegate?
    
    
    
    func CallPostURL(url: String, parameters params: NSDictionary)
    {
        var newString : String
        newString = commandName
        let parameterDictionary: [String: Any] = [
             API_ID: API_ID_VALUE  ,
             API_SECRET: API_SECRET_VALUE ,
             API_REQUEST: newString,
             DATA:params
        ]
       
        var userDic = NSMutableDictionary();
        var headerDic = [String: String]()
        if(UserDefaults.standard.object(forKey: USER_DETAILS) == nil )
        {
            headerDic = [
                DEVICE_TYPE: "ios",
                DEVICE_ID: DEVICE_UNIQUE_IDETIFICATION,
                AUTHORIZATION:ACCESS_KEY
            ]
        }
        else
        {
            userDic = (UserDefaults.standard.object(forKey: USER_DETAILS) as? NSMutableDictionary)!
           
            if (userDic["access_token"] != nil)
            {
                let authorization = "\(ACCESS_KEY) \(userDic["access_token"] as! String)"
            
                headerDic = [
                    DEVICE_TYPE: "ios",
                    DEVICE_ID: DEVICE_UNIQUE_IDETIFICATION,
                    AUTHORIZATION:authorization
                ]
            }else{
                headerDic = [
                    DEVICE_TYPE: "ios",
                    DEVICE_ID: DEVICE_UNIQUE_IDETIFICATION,
                    AUTHORIZATION:ACCESS_KEY
                ]
            }
        }
        print(headerDic)
        print(parameterDictionary)
        
        //URLEncoding
        Alamofire.request(url, method: .post, parameters: parameterDictionary ,encoding: URLEncoding.default, headers: headerDic).responseJSON {
            response in
            switch response.result {
            case .success:
                if response.response != nil
                {
                    if let JSON = response.result.value
                    {
                        let responseObject = JSON as! NSDictionary
                        let result : NSMutableDictionary = responseObject.mutableCopy() as! NSMutableDictionary
                       
                        if (self.commandName != nil) {
                            result[COMMAND] = self.commandName
                        }
                        if (self.tag != nil) {
                            result[TAG] = self.tag
                        }
                        self.delegate?.onResult(result: result)

                    }
                }

                break
            case .failure(let error):
                self.delegate?.onFault(error: error as NSError)
            }
        }
        
    }
    
    
    func CallGetURL(url: String)
    {
        
            Alamofire.request(url, method: .get, parameters: nil ,encoding: URLEncoding.default, headers: nil).responseJSON {
            response in
            switch response.result {
            case .success:
                if response.response != nil
                {
                    if let JSON = response.result.value
                    {
                        let responseObject = JSON as! NSDictionary
                        let result : NSMutableDictionary = responseObject.mutableCopy() as! NSMutableDictionary
                        
                        if (self.commandName != nil) {
                            result[COMMAND] = self.commandName
                            self.delegate?.onResult(result: result)
                        }
                    }
                }
                
                break
            case .failure(let error):
                self.delegate?.onFault(error: error as NSError)
            }
        }
        
    }

    func CallDeleteURL(url: String, parameters params: Parameters) {
        var headerDic = [String: String]()
        headerDic = [
            "X-Requested-With": "XMLHttpRequest",
            "Content-Type": "application/x-www-form-urlencoded",
            "Env":"YetiVisit360",
            "Authorization":Utility.getAccessToken()
        ]
        
        Alamofire.request(url, method: .delete, parameters: params, encoding: URLEncoding.default, headers: headerDic).responseJSON{
            response in
            switch response.result {
            case .success:
                let statusCode =  response.response?.statusCode
                
                if response.response != nil
                {
                    if let JSON = response.result.value
                    {
                        let responseObject = JSON as! NSDictionary
                        let result : NSMutableDictionary = responseObject.mutableCopy() as! NSMutableDictionary
                        
                        let newdict = self.removeNullsFromDictionary(origin: result as! [String : AnyObject])
                        print(newdict)
                        var resultDictionary = NSMutableDictionary()
                        resultDictionary = newdict
                        print("Final dictionary:\(resultDictionary)")
                        
                        if (self.commandName != nil) {
                            resultDictionary[COMMAND] = self.commandName
                        }
                        if (self.tag != nil) {
                            resultDictionary[TAG] = self.tag
                        }
                        resultDictionary[STATUS_CODE] = statusCode
                        self.delegate?.onResult(result: resultDictionary)
                        
                    }
                }
                
                break
            case .failure(let error):
                let errorDic = response.response?.allHeaderFields as NSDictionary?
                if(errorDic != nil)
                {
                    let errorCode = errorDic!["X-YetiVisit-Code"] as! String
                    let errorCodeInt = Int(errorCode)
                    let errorMessage = Utility.getExceptionMessage(exceptionId: errorCodeInt!)
                    if errorCodeInt == 301{
                        print("need to logout....")
                        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
                        appDelegate?.logoutUserLocally()
                        Utility.hideIndicator()
                        Utility.showErrorMessage(vc: (appDelegate?.window?.rootViewController)!,message: errorMessage)
                    }else{
                        self.delegate?.onFault(error: error as NSError, errorMessage: errorMessage, errorCode: errorCodeInt! )
                    }
                    
                }
                else
                {
                    print("fail....")
                    self.delegate?.onFault(error: error as NSError, errorMessage: Utility.getLocalizdString(value: "WE_ARE_SORRY_AN_UNKNOWN_ERROR_OCCURED"), errorCode: 0  )
                    
                }
            }
        }
    }
}
