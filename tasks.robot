*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library  RPA.Browser.Selenium
Library  RPA.HTTP
Library  RPA.PDF
Library  RPA.Tables
Library  RPA.Archive

*** Variables ***
${website_url}    https://robotsparebinindustries.com/#/robot-order
${csv_file_url}    https://robotsparebinindustries.com/orders.csv
${receipt_path}    ${OUTPUT_DIR}${/}receipts
${order_button}    //*[@id="order"]

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open robot order website
    Close the annoying modal
    Download robot order csv
    ${orders}  Get order
    Loop the order  ${orders}
    Create a ZIP file of receipt PDF files

*** Keywords ***
Open robot order website
    Open Available Browser    ${website_url}
    Maximize Browser Window


Download robot order csv
    Download    ${csv_file_url}    overwrite=${True}

Get order
    ${orders}  Read table from CSV    orders.csv
    [return]  ${orders}

Loop the order
    [Arguments]  ${orders}
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Fill the form    ${order}
        ${pdf}    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}    Take a screenshot of the robot    ${order}[Order number]
        Click Button When Visible    id:order-another
        Open pdf file and embede screenshot    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds    2 min    5 sec    Close the annoying modal
    END

Close the annoying modal
    Click Button When Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${order}
    Select From List By Value   id:head  ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //div[@id='root']/div/div/div/div/form/div[3]/input    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Execute Javascript    window.scrollTo(0, document.body.scrollHeight)
    Sleep    0.2
    Wait Until Element Is Visible    ${order_button}
    Click Button  ${order_button}
    ${result}    Does Page Contain Element    ${order_button}
    WHILE    ${result}
        Wait And Click Button  ${order_button}
        ${result}    Does Page Contain Element    ${order_button}
    END
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${pdf_path}    Set Variable     ${receipt_path}${/}${order_number}.pdf
    ${receipt_element}    Set Variable    id:receipt
    Wait Until Element Is Visible    ${receipt_element}
    ${order_receipt}    Get Element Attribute    ${receipt_element}    outerHTML
    Html To Pdf    ${order_receipt}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${robot_image_preview_element}    Set Variable    id:robot-preview-image
    Wait Until Element Is Visible    ${robot_image_preview_element}
    ${screenshot}    Screenshot    ${robot_image_preview_element}    ${receipt_path}${/}${order_number}.png
    RETURN    ${screenshot}

Open pdf file and embede screenshot
    [Arguments]    ${screenshot}    ${pdf}
    
    Open Pdf    ${pdf}
    ${files}    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf
    
Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${receipt_path}    ${receipt_path}.zip