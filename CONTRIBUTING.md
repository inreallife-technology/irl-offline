# Contributing

One pull request, one file. Name files in lowercase with hyphens, like `sunday-photography-walk.yml`.

Run `bin/check` before you push if you have Ruby; the pull request runs it anyway.

## A map entry

`map/<country>/<city>/<name>.yml`, for example `map/fr/paris/sunday-photography-walk.yml`:

```yaml
city: Paris
country: FR
activity: Sunday photography walk
category: photography
group_size: 6
i_would_host: true
description: >
  A slow walk along the canal, swapping tips, no gear snobbery.
```

- `country` is the two-letter code, and the folder is the same code in lowercase.
- The city folder is the city name in lowercase with hyphens, without accents: `saint-etienne`.
- `activity`: what you'd do, up to 80 characters.
- `category`: one lowercase word, or a few joined by hyphens. Not dating (see the README).
- `group_size`: from 2 to 15, counting the host.
- `i_would_host`: `true` if you'd run it yourself, `false` if you'd like to join.
- `description`: what it's like, up to 280 characters.

City level only. No address, venue, date, email, phone number or link.

## A manifesto line

`manifesto/<name>.md`: one statement on one line, up to 140 characters.

```markdown
The best conversations don't have a comment section.
```

## A principle

`constitution/<name>.md`: the principle as a heading, then why, then what it means in practice. Up to 600 characters for the three parts.

```markdown
# Everyone can leave

**Why:** Nobody should stay somewhere they don't feel good, or owe anyone a reason.

**In practice:** Leave at any time without explaining. The host says so at the start, and nobody asks why.
```

## What the check refuses

- A file in the wrong folder, or with the wrong name or extension.
- A missing or extra field, or YAML that doesn't read.
- Text over the length.
- An email address, phone number or link.
- An entry that's the same as one already here, or nearly. Improve that one instead.

Everything else is a person's call.
