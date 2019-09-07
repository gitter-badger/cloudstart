/*
 Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License").
 You may not use this file except in compliance with the License.
 A copy of the License is located at

 http://aws.amazon.com/apache2.0

 or in the "license" file accompanying this file. This file is distributed
 on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 express or implied. See the License for the specific language governing
 permissions and limitations under the License.
 */


import AWSCore
import AWSAPIGateway

public class CloudStartClient: AWSAPIGatewayClient {

	static let AWSInfoClientKey = "CloudStartClient"

	private static let _serviceClients = AWSSynchronizedMutableDictionary()
	private static let _defaultClient:CloudStartClient = {
		var serviceConfiguration: AWSServiceConfiguration? = nil
        let serviceInfo = AWSInfo.default().defaultServiceInfo(AWSInfoClientKey)
        if let serviceInfo = serviceInfo {
            serviceConfiguration = AWSServiceConfiguration(region: serviceInfo.region, credentialsProvider: serviceInfo.cognitoCredentialsProvider)
        } else if (AWSServiceManager.default().defaultServiceConfiguration != nil) {
            serviceConfiguration = AWSServiceManager.default().defaultServiceConfiguration
        } else {
            serviceConfiguration = AWSServiceConfiguration(region: .Unknown, credentialsProvider: nil)
        }
        
        return CloudStartClient(configuration: serviceConfiguration!)
	}()
    
	/**
	 Returns the singleton service client. If the singleton object does not exist, the SDK instantiates the default service client with `defaultServiceConfiguration` from `AWSServiceManager.defaultServiceManager()`. The reference to this object is maintained by the SDK, and you do not need to retain it manually.
	
	 If you want to enable AWS Signature, set the default service configuration in `func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?)`
	
	     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
	        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
	        AWSServiceManager.default().defaultServiceConfiguration = configuration
	 
	        return true
	     }
	
	 Then call the following to get the default service client:
	
	     let serviceClient = CloudStartClient.default()

     Alternatively, this configuration could also be set in the `info.plist` file of your app under `AWS` dictionary with a configuration dictionary by name `CloudStartClient`.
	
	 @return The default service client.
	 */ 
	 
	public class func `default`() -> CloudStartClient{
		return _defaultClient
	}

	/**
	 Creates a service client with the given service configuration and registers it for the key.
	
	 If you want to enable AWS Signature, set the default service configuration in `func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)`
	
	     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	         let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
	         let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialProvider)
	         CloudStartClient.registerClient(withConfiguration: configuration, forKey: "USWest2ABCCloudStartClient")
	
	         return true
	     }
	
	 Then call the following to get the service client:
	
	
	     let serviceClient = CloudStartClient.client(forKey: "USWest2ABCCloudStartClient")
	
	 @warning After calling this method, do not modify the configuration object. It may cause unspecified behaviors.
	
	 @param configuration A service configuration object.
	 @param key           A string to identify the service client.
	 */
	
	public class func registerClient(withConfiguration configuration: AWSServiceConfiguration, forKey key: String){
		_serviceClients.setObject(CloudStartClient(configuration: configuration), forKey: key  as NSString);
	}

	/**
	 Retrieves the service client associated with the key. You need to call `registerClient(withConfiguration:configuration, forKey:)` before invoking this method or alternatively, set the configuration in your application's `info.plist` file. If `registerClientWithConfiguration(configuration, forKey:)` has not been called in advance or if a configuration is not present in the `info.plist` file of the app, this method returns `nil`.
	
	 For example, set the default service configuration in `func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) `
	
	     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	         let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
	         let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialProvider)
	         CloudStartClient.registerClient(withConfiguration: configuration, forKey: "USWest2ABCCloudStartClient")
	
	         return true
	     }
	
	 Then call the following to get the service client:
	 
	 	let serviceClient = CloudStartClient.client(forKey: "USWest2ABCCloudStartClient")
	 
	 @param key A string to identify the service client.
	 @return An instance of the service client.
	 */
	public class func client(forKey key: String) -> CloudStartClient {
		objc_sync_enter(self)
		if let client: CloudStartClient = _serviceClients.object(forKey: key) as? CloudStartClient {
			objc_sync_exit(self)
		    return client
		}

		let serviceInfo = AWSInfo.default().defaultServiceInfo(AWSInfoClientKey)
		if let serviceInfo = serviceInfo {
			let serviceConfiguration = AWSServiceConfiguration(region: serviceInfo.region, credentialsProvider: serviceInfo.cognitoCredentialsProvider)
			CloudStartClient.registerClient(withConfiguration: serviceConfiguration!, forKey: key)
		}
		objc_sync_exit(self)
		return _serviceClients.object(forKey: key) as! CloudStartClient;
	}

	/**
	 Removes the service client associated with the key and release it.
	 
	 @warning Before calling this method, make sure no method is running on this client.
	 
	 @param key A string to identify the service client.
	 */
	public class func removeClient(forKey key: String) -> Void{
		_serviceClients.remove(key)
	}
	
	init(configuration: AWSServiceConfiguration) {
	    super.init()
	
	    self.configuration = configuration.copy() as! AWSServiceConfiguration
	    var URLString: String = "https://m7d0omwzfj.execute-api.eu-west-2.amazonaws.com/dev"
	    if URLString.hasSuffix("/") {
	        URLString = URLString.substring(to: URLString.index(before: URLString.endIndex))
	    }
	    self.configuration.endpoint = AWSEndpoint(region: configuration.regionType, service: .APIGateway, url: URL(string: URLString))
	    let signer: AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: configuration.credentialsProvider, endpoint: self.configuration.endpoint)
	    if let endpoint = self.configuration.endpoint {
	    	self.configuration.baseURL = endpoint.url
	    }
	    self.configuration.requestInterceptors = [AWSNetworkingRequestInterceptor(), signer]
	}

	
    /*
     
     
     
     return type: DescribeInstancesResult
     */
    public func instancesGet() -> AWSTask<DescribeInstancesResult> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    let queryParameters:[String:Any] = [:]
	    
	    let pathParameters:[String:Any] = [:]
	    
	    return self.invokeHTTPRequest("GET", urlString: "/instances", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: nil, responseClass: DescribeInstancesResult.self) as! AWSTask<DescribeInstancesResult>
	}

	
    /*
     
     
     @param instanceId 
     @param body 
     
     return type: ChangeInstanceStateResponse
     */
    public func instancesInstanceIdPatch(instanceId: String, body: ChangeInstanceStateRequest) -> AWSTask<ChangeInstanceStateResponse> {
	    let headerParameters = [
                   "Content-Type": "application/json",
                   "Accept": "application/json",
                   
	            ]
	    
	    let queryParameters:[String:Any] = [:]
	    
	    var pathParameters:[String:Any] = [:]
	    pathParameters["instanceId"] = instanceId
	    
	    return self.invokeHTTPRequest("PATCH", urlString: "/instances/{instanceId}", pathParameters: pathParameters, queryParameters: queryParameters, headerParameters: headerParameters, body: body, responseClass: ChangeInstanceStateResponse.self) as! AWSTask<ChangeInstanceStateResponse>
	}




}
