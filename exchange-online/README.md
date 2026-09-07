# exchange-online labs

Run from the repository root with PowerShell 7.2+.

## Mailbox auditor

Reports external forwarding, delegates, FullAccess and shared-mailbox ownership review from normalized fixtures. No Exchange connection.

```powershell
./exchange-online/Get-MailboxAudit.ps1 -InputPath samples/mailboxes.json
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.
