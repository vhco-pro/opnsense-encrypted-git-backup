# Source from the publisher and dispatch scripts before effects or downloads.
case "$1" in
    fixture)
        for url in "${GITHUB_API_URL:?}" "${PAGES_API:?}" "${PAGES_ASSET_API:?}" "${FEED_URL:?}"; do
            [[ "$url" =~ ^http://127[.]0[.]0[.]1:[0-9]+(/[A-Za-z0-9/_-]*)?$ ]] || exit 64
        done
        environment=feed-fixture
        github_headers=()
        pages_headers=()
        ;;
    production)
        if [[ "${GITHUB_ACTIONS:-}" != true || "${GITHUB_EVENT_NAME:-}" != workflow_dispatch ||
              "${GITHUB_WORKFLOW_REF:-}" != "${GITHUB_REPOSITORY:-}/.github/workflows/feed.yml@refs/heads/main" ||
              "${FEED_PRODUCTION_APPROVED:-}" != true ||
              -z "${FEED_JOURNAL_TOKEN:-}" || -z "${PAGES_TOKEN:-}" ]]; then
            echo 'Production publication requires the approved protected workflow.' >&2
            exit 64
        fi
        [[ "${GITHUB_API_URL:?}" == https://api.github.com ]]
        [[ "${PAGES_API:?}" =~ ^https://api[.]cloudflare[.]com/client/v4/accounts/[a-f0-9]{32}/pages/projects/[a-z0-9-]+$ ]]
        [[ "${PAGES_ASSET_API:?}" == https://api.cloudflare.com/client/v4/pages/assets ]]
        [[ "${FEED_URL:?}" =~ ^https://[a-zA-Z0-9.-]+(/[A-Za-z0-9/_-]*)?$ ]]
        : "${FEED_NATIVE_MANIFEST:?}" "${FEED_HISTORY:?}"
        environment=signed-feed-journal
        github_headers=(-H "Authorization: Bearer $FEED_JOURNAL_TOKEN" -H 'Accept: application/vnd.github+json')
        pages_headers=(-H "Authorization: Bearer $PAGES_TOKEN")
        ;;
    *) exit 64 ;;
esac
