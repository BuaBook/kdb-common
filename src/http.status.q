// HTTP Query Library - Status Enumeration
// Copyright (c) 2021 Jaskirat Rajasansir

// Contains English descriptions of each HTTP status code as defined by https://httpstatuses.com/

.http.status:(`int$())!();

/ Informational
.http.status[100]:"Continue";
.http.status[101]:"Switching Protocols";
.http.status[102]:"Processing";

/ Success
.http.status[200]:"OK";
.http.status[201]:"Created";
.http.status[202]:"Accepted";
.http.status[203]:"Non-authoritative Information";
.http.status[204]:"No Content";
.http.status[205]:"Reset Content";
.http.status[206]:"Partial Content";
.http.status[207]:"Multi-Status";
.http.status[208]:"Already Reported";
.http.status[226]:"IM Used";
.http.status[300]:"Multiple Choices";

/ Redirection
.http.status[301]:"Moved Permanently";
.http.status[302]:"Found";
.http.status[303]:"See Other";
.http.status[304]:"Not Modified";
.http.status[305]:"Use Proxy";
.http.status[307]:"Temporary Redirect";
.http.status[308]:"Permanent Redirect";

/ Client Error
.http.status[400]:"Bad Request";
.http.status[401]:"Unauthorized";
.http.status[402]:"Payment Required";
.http.status[403]:"Forbidden";
.http.status[404]:"Not Found";
.http.status[405]:"Method Not Allowed";
.http.status[406]:"Not Acceptable";
.http.status[407]:"Proxy Authentication Required";
.http.status[408]:"Request Timeout";
.http.status[409]:"Conflict";
.http.status[410]:"Gone";
.http.status[411]:"Length Required";
.http.status[412]:"Precondition Failed";
.http.status[413]:"Payload Too Large";
.http.status[414]:"Request-URI Too Long";
.http.status[415]:"Unsupported Media Type";
.http.status[416]:"Requested Range Not Satisfiable";
.http.status[417]:"Expectation Failed";
.http.status[418]:"I'm a teapot";
.http.status[421]:"Misdirected Request";
.http.status[422]:"Unprocessable Entity";
.http.status[423]:"Locked";
.http.status[424]:"Failed Dependency";
.http.status[426]:"Upgrade Required";
.http.status[428]:"Precondition Required";
.http.status[429]:"Too Many Requests";
.http.status[431]:"Request Header Fields Too Large";
.http.status[444]:"Connection Closed Without Response";
.http.status[451]:"Unavailable For Legal Reasons";
.http.status[499]:"Client Closed Request";

/ Server Error
.http.status[500]:"Internal Server Error";
.http.status[501]:"Not Implemented";
.http.status[502]:"Bad Gateway";
.http.status[503]:"Service Unavailable";
.http.status[504]:"Gateway Timeout";
.http.status[505]:"HTTP Version Not Supported";
.http.status[506]:"Variant Also Negotiates";
.http.status[507]:"Insufficient Storage";
.http.status[508]:"Loop Detected";
.http.status[510]:"Not Extended";
.http.status[511]:"Network Authentication Required";
.http.status[599]:"Network Connect Timeout Error";
