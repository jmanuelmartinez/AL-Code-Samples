codeunit 58002 "Dummy Batch Upload v19"
{
    trigger OnRun()
    begin

    end;

    procedure BatchUploadPOAttachments()
    var
        ServerFolder: Text;
        FileList: List of [Text];
        FileName: Text;
        PONumber: Text;
        PORec: Record "Purchase Header";
        ModFileName: Text;
        ProgressBar: Dialog;
        ProgressCounter: Integer;
        FileExtension: Text;
    begin

        // Initialize Progress Bar
        ProgressBar.Open('Uploading files... #1######');
        ProgressCounter := 0;

        // Define the server folder path (to be defined as )
        ServerFolder := 'C:\DummyTestFolder\';

        // Get the list of files in the server folder
        FileList := GetFilesFromFolder(ServerFolder);

        // Loop through each file
        foreach FileName in FileList do begin
            // Update Progress Bar
            ProgressCounter += 1;
            ProgressBar.Update(1, ProgressCounter);

            // Remove directory from the full path to get just the file name
            ModFileName := GetFileNameFromFullPath(FileName);

            // Extract file extension
            FileExtension := GetFileExtension(FileName);

            // Remove file extension from the file name
            ModFileName := RemoveFileExtension(ModFileName);

            // Extract PO Number from FileName (which now has no extension)
            PONumber := ModFileName;

            // Attach the document from the folder to its corresponding PO
            AttachFileToPO(PONumber, FileName, ModFileName, FileExtension);
        end;
        // Close Progress Bar
        ProgressBar.Close();
    end;

    procedure GetFilesFromFolder(ServerFolder: Text): List of [Text]
    var
        NameValueBuffer: Record "Name/Value Buffer";
        FileList: List of [Text];
        FileManagement: Codeunit "File Management";
    begin
        // Clear the NameValueBuffer table if needed
        NameValueBuffer.DeleteAll();

        // Get the list of files in the server folder
        FileManagement.GetServerDirectoryFilesList(NameValueBuffer, ServerFolder);

        // Check if any files were found
        if NameValueBuffer.FindSet() then begin
            repeat
                FileList.Add(NameValueBuffer.Name);
            until NameValueBuffer.Next() = 0;
        end else begin
            // Handle the case where no files were found or directory doesn't exist
        end;

        exit(FileList);
    end;

    procedure GetFileNameFromFullPath(FullPath: Text): Text
    var
        LastSlashPosition: Integer;
    begin
        // Find the position of the last slash in the full path
        LastSlashPosition := GetLastDelimiter('\', FullPath);

        // If a slash is found, extract the part after the last slash as the file name
        if LastSlashPosition > 0 then
            exit(CopyStr(FullPath, LastSlashPosition + 1))
        else
            exit(FullPath); // Return the full path if no slash is found (it's already just a file name)
    end;

    procedure RemoveFileExtension(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        // Find the position of the dot that separates the file name from the extension
        DotPosition := GetLastDelimiter('.', FileName);

        // If a dot is found, extract the part before the dot as the file name without extension
        if DotPosition > 0 then
            exit(CopyStr(FileName, 1, DotPosition - 1))
        else
            exit(FileName); // Return the original file name if it doesn't contain a dot
    end;

    procedure GetLastDelimiter(Delimiter: Char; TextToSearch: Text): Integer
    var
        i: Integer;
        CurrentChar: Text;
        DelimiterText: Text;
    begin
        DelimiterText := Format(Delimiter); // Convert Char to Text for comparison
        for i := StrLen(TextToSearch) downto 1 do begin
            CurrentChar := CopyStr(TextToSearch, i, 1);
            if CurrentChar = DelimiterText then
                exit(i);
        end;
        exit(0);
    end;

    procedure AttachFileToPO(PONumber: Text; FilePath: Text; FileName: Text; FileExtension: Text)
    var
        RecRef: RecordRef;
        PurchaseHeader: Record "Purchase Header";
        InStream: InStream;
        FileManagement: Codeunit "File Management";
        IsAttachmentSaved: Boolean;
        PurchDocType: Enum "Purchase Document Type";
        ImportFile: File;
    begin
        // Find the Purchase Header record
        if PurchaseHeader.Get(PurchDocType::Order, PONumber) then begin
            RecRef.GetTable(PurchaseHeader);

            if File.Exists(FilePath) then begin
                ImportFile.Open(FilePath);
                ImportFile.CreateInStream(InStream);
            end else begin
                Error('File %1 not found.', FilePath);
            end;

            // Use the SaveAttachment method to save the attachment
            IsAttachmentSaved := SaveAttachment(InStream, RecRef, FileName, FileExtension);

            ImportFile.Close();

            // For debugging purposes
            // if IsAttachmentSaved then
            //     Message('Successfully attached file %1 to PO %2', FilePath, PONumber)
            // else
            //     Error('Failed to attach file %1 to PO %2', FilePath, PONumber);
        end else begin
            Error('Purchase Order %1 not found.', PONumber);
        end;
    end;

    procedure GetFileExtension(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        // Find the position of the last dot in the file name
        DotPosition := GetLastDelimiter('.', FileName);

        // If a dot is found, extract the part after the dot as the file extension
        if DotPosition > 0 then
            exit(CopyStr(FileName, DotPosition + 1))
        else
            exit(''); // Return an empty string if the file name doesn't contain a dot
    end;

    local procedure SaveAttachment(DocStream: InStream; RecRef: RecordRef; FileName: Text; FileExtension: Text): Boolean;
    var
        DocAttach: Record "Document Attachment";
        Variable: Text;
    begin
        DocAttach.Validate("File Name", FileName);
        DocAttach.Validate("File Extension", FileExtension);
        DocAttach."Document Reference ID".ImportStream(DocStream, '');
        if not DocAttach."Document Reference ID".HasValue then
            exit(false);

        DocAttach.InitFieldsFromRecRef(RecRef);
        OnBeforeInsertAttachment(DocAttach, RecRef);
        exit(DocAttach.Insert(true));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;
}