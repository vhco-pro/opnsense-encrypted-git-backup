<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Encrypted Git backup status') }}</h2>
        <p><a href="/diag_backup.php">{{ lang._('Backups settings') }}</a></p>
        <dl aria-live="polite">
            <dt>{{ lang._('Last attempt') }}</dt><dd id="backup-attempt">—</dd>
            <dt>{{ lang._('Outcome') }}</dt><dd id="backup-outcome" data-unavailable="{{ lang._('Unavailable') | e }}">—</dd>
            <dt>{{ lang._('Failure category') }}</dt><dd id="backup-category">—</dd>
            <dt>{{ lang._('Last verified success') }}</dt><dd id="backup-verified">—</dd>
            <dt>{{ lang._('Remote commit') }}</dt><dd id="backup-commit"><code style="white-space: normal; overflow-wrap: anywhere">—</code></dd>
        </dl>
    </div>
</div>
<script>
$(function () {
    $.getJSON('/api/encrypted_git_backup/status/read', function (status) {
        $('#backup-attempt').text(status.attempt?.attempt ?? '—');
        $('#backup-outcome').text(status.attempt?.outcome ?? '—');
        $('#backup-category').text(status.attempt?.category ?? '—');
        $('#backup-verified').text(status.verification?.observedAt ?? '—');
        $('#backup-commit code').text(status.verification?.commit ?? '—');
    }).fail(function () {
        $('#backup-outcome').text($('#backup-outcome').attr('data-unavailable'));
    });
});
</script>
