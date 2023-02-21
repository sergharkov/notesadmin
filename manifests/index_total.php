<?php                                     
// Create a cURL handle                                                            
                                                                                   
$ch = curl_init('http://net1_nginx:8080');                                         
//curl_exec($ch);                                                                  
echo 'fixed link with prefix http://net1_nginx:8080 >>>> ', curl_exec($ch), "</br>";
// Close handle                                           
curl_close($ch);                                                                    
                                                                                    
$ch = curl_init('http://net2_nginx:8080');                                          
//curl_exec($ch);                                                                   
echo 'fixed link with prefix http://net2_nginx:8080 >>>> ', curl_exec($ch), "</br>";
// Close handle                                                                     
curl_close($ch);                          
                                                                                    
                                                                                    
$ch = curl_init('http://net3_nginx:8080');                                          
//curl_exec($ch);                                                                   
echo 'fixed link with prefix http://net3_nginx:8080 >>>> ', curl_exec($ch), "</br>";
// Close handle                                                                     
curl_close($ch);                                                                    
                                       
echo '----------------------', "</br>";              
echo '----------------------', "</br>";              
echo '----------------------', "</br>";                                        
                                                                               
$ch = curl_init('http://nginx:8080');                                          
//curl_exec($ch);                                                                   
echo 'fixed link with prefix http://nginx:8080 >>>> ', curl_exec($ch), "</br>";
// Close handle                                                                
curl_close($ch);                                                               
                                                                               
                                                                               
//$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);                          
//echo '  Unexpected HTTP code: ', $http_code, "\n";                           
                                                                               
?>
