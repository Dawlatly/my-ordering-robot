*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.RobotLogListener
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           Collections

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${order_url}=    Get the URL
    Save the URL to the vault    ${order_url}
    Open the robot order website
    ${orders}=    Get orders    ${order_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${OUTPUT_DIR}${/}${row}[Order number].png    ${OUTPUT_DIR}${/}${row}[Order number].pdf
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Get orders
    [Arguments]    ${order_url}
    Download    ${order_url}[orderurl]
    ${orders}=    Read table from CSV    orders.csv
    Return From Keyword    ${orders}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[type="number"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit the order
    Mute Run On Failure    Page Should Contain Element
    Click Button    order
    Page Should Contain Element    receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    # Wait Until Element Is Visible    id:receipt
    ${order_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_html}    ${OUTPUT_DIR}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${screenshot_list}=    Create List    ${screenshot}:x=0,y=0
    Add Files To Pdf    ${screenshot_list}    ${pdf}    True

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output    receipts.zip    include=*.pdf

Get the URL
    Add heading    Welcome to Robocorp Ordering Robot
    Add text input    orderurl    label=Please enter the URL    placeholder=Over Here !
    ${order_url}=    Run dialog
    [Return]    ${order_url}

Save the URL to the vault
    [Arguments]    ${order_url}
    ${secret}=    Get Secret    urls
    Set To Dictionary    ${secret}    order_url    ${order_url}[orderurl]
    Set Secret    ${secret}
