pageextension 58001 "Dummy Purch. Order List" extends "Purchase Order List"
{
    actions
    {
        addafter("Delete Invoiced")
        {
            action("AttachmentBatchUpload")
            {
                Caption = 'Attachment Batch Upload';
                Image = Attachments;
                Promoted = true;

                trigger OnAction()
                var
                    DummyCodeunit: Codeunit "Dummy Batch Upload v19";
                begin
                    DummyCodeunit.BatchUploadPOAttachments();
                end;
            }
        }
    }
}