%% -*- erlang-indent-level: 4; indent-tabs-mode: nil; fill-column: 80 -*-
%%% Copyright 2012 Erlware, LLC. All Rights Reserved.
%%%
%%% This file is provided to you under the Apache License,
%%% Version 2.0 (the "License"); you may not use this file
%%% except in compliance with the License.  You may obtain
%%% a copy of the License at
%%%
%%%   http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing,
%%% software distributed under the License is distributed on an
%%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%%% KIND, either express or implied.  See the License for the
%%% specific language governing permissions and limitations
%%% under the License.
%%%---------------------------------------------------------------------------
%%% @author Jordan Wilberding <jwilberding@gmail.com>
%%% @copyright (C) 2013 Erlware, LLC.
%%%
%%% @doc 
%%%  An Erlang API for Authorize.net
%%% @end

-module(eauthnet).

-export([new_params/0,
         new_params/2,
         new_params/3,
         charge/1,
         charge/4]).

-include("eauthnet.hrl").

-define(DEFAULT_URL, <<"https://secure.authorize.net/gateway/transact.dll">>).
-define(DEFAULT_TEST_URL, <<"https://test.authorize.net/gateway/transact.dll">>).
-define(DEFAULT_LOGIN, <<"CHANGE_ME">>).
-define(DEFAULT_TRAN_KEY, <<"CHANGE_ME">>).

%%%===================================================================
%%% New record functions
%%%===================================================================

-spec new_params() -> record(authnet_params).
new_params() ->
    {ok, URL} = with_default(application:get_env(eauthnet, url), ?DEFAULT_URL),
    {ok, Login} = with_default(application:get_env(eauthnet, login), ?DEFAULT_LOGIN),
    {ok, TranKey} = with_default(application:get_env(eauthnet, tran_key), ?DEFAULT_TRAN_KEY),
    #authnet_params{url=URL, login=Login, tran_key=TranKey}.

-spec new_params(binary(), binary()) -> record(authnet_params).
new_params(Login, TranKey) ->
    {ok, URL} = with_default(application:get_env(eauthnet, url), ?DEFAULT_URL),
    #authnet_params{url=URL, login=Login, tran_key=TranKey}.

-spec new_params(binary(), binary(), binary()) -> record(authnet_params).
new_params(URL, Login, TranKey) ->
    #authnet_params{url=URL, login=Login, tran_key=TranKey}.

-spec new_result([binary()]) -> record(authnet_result).
new_result([ResponseCode, ResponseSubcode, ResponseReasonCode, ResponseReasonText,
            ApprovalCode, AVSResultCode, TransactionID, InvoiceNumber, Description,
            Amount, Method, TransactionType, CustomerID, CardholderFirstName,
            CardholderLastName, Company, BillingAddress, City, State, Zip, Country,
            Phone, Fax, Email, ShipToFirstName, ShipToLastName, ShipToCompany,
            ShipToAddress, ShipToCity, ShipToState, ShipToZip, ShipToCountry,
            TaxAmount, DutyAmount, FreightAmount, TaxExemptFlag, PONumber,
            MD5Hash, CardCodeResponseCode, CAVVResponseCode | _T]) ->
    #authnet_result{response_code=ResponseCode,
                    response_subcode=ResponseSubcode,
                    response_reason_code=ResponseReasonCode,
                    response_reason_text=ResponseReasonText,
                    approval_code=ApprovalCode,
                    avs_result_code=AVSResultCode,
                    transaction_id=TransactionID,
                    invoice_number=InvoiceNumber,
                    description=Description,
                    amount=Amount, method=Method,
                    transaction_type=TransactionType,
                    customer_id=CustomerID,
                    cardholder_first_name=CardholderFirstName,
                    cardholder_last_name=CardholderLastName,
                    company=Company,
                    billing_address=BillingAddress,
                    city=City,
                    state=State,
                    zip=Zip,
                    country=Country,
                    phone=Phone,
                    fax=Fax,
                    email=Email,
                    ship_to_first_name=ShipToFirstName,
                    ship_to_last_name=ShipToLastName,
                    ship_to_company=ShipToCompany,
                    ship_to_address=ShipToAddress,
                    ship_to_city=ShipToCity,
                    ship_to_state=ShipToState,
                    ship_to_zip=ShipToZip,
                    ship_to_country=ShipToCountry,
                    tax_amount=TaxAmount,
                    duty_amount=DutyAmount,
                    freight_amount=FreightAmount,
                    tax_exempt_flag=TaxExemptFlag,
                    po_number=PONumber,
                    md5_hash=MD5Hash,
                    card_code_response_code=CardCodeResponseCode,
                    cavv_response_code=CAVVResponseCode}.


%%%===================================================================
%%% Charge functions
%%%===================================================================

-spec charge(record(authnet_params)) -> record(authnet_result).
charge(#authnet_params{url=URL, login=Login, tran_key=TranKey, card_num=CardNum, exp_date=ExpDate, card_code=CardCode, amount=Amount}) ->
    Method = post,
    Headers = [],
    Payload = << <<"x_delim_data=TRUE&x_delim_char=|&x_relay_response=FALSE&x_url=FALSE&x_version=3.1&x_method=CC&x_type=AUTH_CAPTURE&x_login=">>/binary, Login/binary, <<"&x_tran_key=">>/binary , TranKey/binary, <<"&x_card_num=">>/binary, CardNum/binary, <<"&x_exp_date=">>/binary, ExpDate/binary, <<"&x_amount=">>/binary, Amount/binary, <<"&x_po_num=0&x_tax=0&x_card_code=">>/binary, CardCode/binary >>,
    Options = [],
    {ok, _StatusCode, _RespHeaders, Client} = hackney:request(Method, URL, Headers, Payload, Options),
    {ok, Body, _Client1} = hackney:body(Client),
    new_result(binary:split(Body, [<<"|">>], [global])).

-spec charge(binary(), binary(), binary(), binary()) -> record(authnet_result).
charge(CardNum, ExpDate, CardCode, Amount) ->
    AuthParams = new_params(),
    AuthParams2 = AuthParams#authnet_params{card_num=CardNum, exp_date=ExpDate, card_code=CardCode, amount=Amount},
    charge(AuthParams2).


%%%===================================================================
%%% Local helper functions
%%%===================================================================

-spec with_default(any(), any()) -> any().
with_default(X, Y) ->
    case X of
        undefined ->
            {ok, Y};
        _ ->
            X
    end.
