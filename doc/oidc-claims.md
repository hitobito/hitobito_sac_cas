# SAC/CAS specific OIDC claims

In the SAC wagon, some additional attributes are added to the OIDC claims.

## Profile picture URL
The `name` and `with_roles` scope additionally yield the profile picture URL of the user who just logged in. The profile picture URL is exposed in the Userinfo endpoint.

## layer_group_id in `with_roles` scope
For easily determining the Sektion / Ortsgruppe / Nationalverband (used by third-party-applications for authorization), the `layer_group_id` of each role's group is exposed in the `with_roles` claims.

## New scope `user_groups`
For "easily parsing" the presence or absence of certain role combinations by some third-party applications, a new scope `user_groups` was introduced.
This scope adds a claim with the key `user_groups` to the userinfo endpoint. The contents of this claim is a JSON list of strings. Each string represents either directly an active role (e.g. `"Group::Geschaeftsstelle::Mitarbeiter#8"` for a role of type `Group::Geschaeftsstelle::Mitarbeiter` in the group with id 8), or a compounded / "calculated role" such as `"SAC_employee"` which, if present in the userinfo endpoint, stands for "the user has any active role in any `Geschaeftsstelle` group".

The name of this scope and claim is a compromise: These "calculated roles" are used for deriving the permissions of the user in third-party applications. Many third-party applications use permission mechanism which they refer to internally as "groups" (as in, Benutzergruppen). However, in hitobito, "roles" are used for assigning and grouping permissions, and "groups" as a term is used for a different concept. The term "user_groups" presents a middle-ground, being close to the Benutzergruppen of the third-party applications, but still distinct from hitobito's "groups".

## Example payloads

### Userinfo endpoint with `email` scope
Note: This payload is currently unmodified from hitobito core.
```json
{
  "sub": "600000",
  "email": "hitobito-sac-cas@puzzle.ch"
}
```

### Userinfo endpoint with `name` scope
```json
{
  "sub": "600000",
  "first_name": "Puzzle",
  "last_name": "ITC",
  "nickname": null,
  "address": null,
  "zip_code": "",
  "town": null,
  "country": null,
  "picture_url": "http://localhost:3000/packs/media/images/profil-d4d04543c5d265981cecf6ce059f2c5d.png"
}
```

### Userinfo endpoint with `openid`, `with_roles` and `email` Scope
```json
{
  "sub": "600000",
  "roles": [
    {
      "group_id": 8,
      "group_name": "1 Geschäftsstelle",
      "role": "Group::Geschaeftsstelle::Mitarbeiter",
      "role_class": "Group::Geschaeftsstelle::Mitarbeiter",
      "role_name": "Mitarbeiter*in (schreibend)",
      "permissions": [
        "layer_and_below_full"
      ],
      "layer_group_id": 1
    }
  ],
  "picture_url": "http://localhost:3000/packs/media/images/profil-d4d04543c5d265981cecf6ce059f2c5d.png",
  "first_name": "Puzzle",
  "last_name": "ITC",
  "nickname": null,
  "company_name": "Puzzle ITC",
  "company": true,
  "email": "hitobito-sac-cas@puzzle.ch",
  "address": null,
  "zip_code": "",
  "town": null,
  "country": null,
  "gender": null,
  "birthday": "1999-09-09",
  "primary_group_id": 8,
  "language": "de",
  "phone": null,
  "membership_years": 0
}
```

### Userinfo endpoint with `openid`, `with_roles` and `user_groups` Scope
```json
{
  "sub": "600000",
  "roles": [
    {
      "group_id": 8,
      "group_name": "1 Geschäftsstelle",
      "role": "Group::Geschaeftsstelle::Mitarbeiter",
      "role_class": "Group::Geschaeftsstelle::Mitarbeiter",
      "role_name": "Mitarbeiter*in (schreibend)",
      "permissions": [
        "layer_and_below_full"
      ],
      "layer_group_id": 1
    }
  ],
  "picture_url": "http://localhost:3000/packs/media/images/profil-d4d04543c5d265981cecf6ce059f2c5d.png",
  "first_name": "Puzzle",
  "last_name": "ITC",
  "nickname": null,
  "company_name": "Puzzle ITC",
  "company": true,
  "email": "hitobito-sac-cas@puzzle.ch",
  "address": null,
  "zip_code": "",
  "town": null,
  "country": null,
  "gender": null,
  "birthday": "1999-09-09",
  "primary_group_id": 8,
  "language": "de",
  "phone": null,
  "membership_years": 0,
  "user_groups": [
    "SAC_employee",
    "Group::Geschaeftsstelle::Mitarbeiter#8"
  ]
}
```
