# 🧭 TripMood AI

**Your day, matched to your mood.** _Tell us your mood. We build your day._

TripMood AI is an **AI travel assistant** for people who are in a city and don't
know what to do today. You tell it your **city, time, budget, mood, interests,
energy and travel style**, and it builds a realistic **mini day plan** (3–5 stops)
— then you can **chat with the AI** to refine it (cheaper, more relaxed, more
food, hidden gems), including attaching a file (multimodal).

Built for **Le Wagon AI Week** (Bootcamp Bangalore) · Rails 8 + PostgreSQL.

🔗 **Repo:** https://github.com/richardsommerauer/tripmood-ai

---

## Persona & goal

- **Core user:** a traveler with a few free hours in a city.
- **Goal:** _"I don't know what to do today — give me a realistic plan that fits
  how I actually feel."_

## User stories

**Browse**
- As a visitor, I can visit the home page to see the value proposition.
- As a visitor, I can see the list of day plans (trips).
- As a visitor, I can click a plan to see its full itinerary.

**Create / edit / destroy (core model = Trip)**
- As a user, I can fill in a form to plan a new day.
- As a user, I can submit it to generate an AI day plan.
- As a user, I can edit a plan I created (and it regenerates).
- As a user, I can delete a plan I created.

**Chat with the AI about a plan**
- As a user, I can start a chat about one of my trips.
- As a user, I can see the list of chats for a trip.
- As a user, I can open a chat.
- As a user, I can send a message and get an AI reply.
- As a user, I can send a message **with a file attachment** (multimodal).
- As a user, I can send follow-up messages.

## Database schema

```
users (Devise)
  └─ has_many :trips
  └─ has_many :chats

trips           # the core CRUD model = one AI day plan
  user_id, city, duration, budget, mood, energy, travel_style,
  interests:string[] , title, summary, plan:jsonb   # full structured plan
  └─ has_many :chats

chats
  user_id, trip_id, title
  └─ has_many :messages

messages
  chat_id, role ("user"|"assistant"), content:text
  └─ has_one_attached :file   # Active Storage (multimodal)
```

## Routes

| Verb   | Path                         | Controller#action  |
|--------|------------------------------|--------------------|
| GET    | `/`                          | `pages#home`       |
| GET    | `/trips`                     | `trips#index`      |
| GET    | `/trips/new`                 | `trips#new`        |
| POST   | `/trips`                     | `trips#create`     |
| GET    | `/trips/:id`                 | `trips#show`       |
| GET    | `/trips/:id/edit`            | `trips#edit`       |
| PATCH  | `/trips/:id`                 | `trips#update`     |
| DELETE | `/trips/:id`                 | `trips#destroy`    |
| GET    | `/trips/:trip_id/chats`      | `chats#index`      |
| POST   | `/trips/:trip_id/chats`      | `chats#create`     |
| GET    | `/chats/:id`                 | `chats#show`       |
| DELETE | `/chats/:id`                 | `chats#destroy`    |
| POST   | `/chats/:chat_id/messages`   | `messages#create`  |

---

## Tech stack

- **Ruby 3.3** · **Rails 8.1** · **PostgreSQL**
- **Devise** (auth) · **Active Storage** (file attachments)
- **Bootstrap 5.3** + **simple_form** + **Font Awesome** (Le Wagon minimal template)
- AI via **OpenAI Chat Completions** (plain `Net::HTTP`, no extra gem) with a
  **built-in mock fallback** so it always works for a demo.

### AI = service objects (slim controllers)
- `app/services/trip_plan_generator.rb` — builds the day plan from a Trip.
- `app/services/chat_responder.rb` — generates the assistant's chat replies.
- `app/services/openai_client.rb` — thin OpenAI client; never logs the key/prompt.

**Honest by design:** the AI never invents exact prices or live opening hours —
it says _"please check current opening hours"_, _"prices may vary"_, and treats
the plan as flexible, not a fixed booking.

---

## Setup

```bash
bundle install
rails db:create db:migrate db:seed
cp .env.example .env   # optional — add OPENAI_API_KEY for live AI
rails server
```

Open http://localhost:3000.

**Demo login (from seeds):** `demo@tripmood.ai` / `password123`

### Environment variables

| Variable         | Required | Default       | Notes                                   |
|------------------|----------|---------------|-----------------------------------------|
| `OPENAI_API_KEY` | No       | _(none)_      | Empty → app uses the built-in mock plan |
| `OPENAI_MODEL`   | No       | `gpt-4o-mini` | Any OpenAI chat model                   |

> Secrets are never committed: `.env` is git-ignored; only `.env.example` (with a
> placeholder) is tracked. The API key and full prompts are never logged.

---

## Tests

```bash
rails test
```

Integration tests (`test/integration/user_flows_test.rb`) cover: landing loads,
public gallery, auth-gated form, trip creation with a mock plan, validation
errors, the chat flow (user message → assistant reply), ownership, and that a
missing API key never crashes generation.

---

## 🎬 Demo script

1. Open the home page — explain the problem: _"You're in a new city and don't know what to do today."_
2. Sign up / log in.
3. Click **Plan my day** and enter: **Bangalore · 5 hours · low · tired but curious · food + culture + cafés · low energy · relaxed**.
4. **Generate** → show the itinerary (café → culture → walk → local food), matched to the mood.
5. Open **Chat** on the plan → ask _"make it cheaper and add a hidden gem"_ → show the AI reply; attach a file to show multimodal.
6. Make the point: TripMood matches the day to your **mood**, not just the tourist checklist.

## Deploy (Heroku)

```bash
heroku create
heroku addons:create heroku-postgresql:essential-0
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set OPENAI_API_KEY=...   # optional; omit to demo with the mock
git push heroku master
# db:migrate runs automatically via the Procfile `release` step
heroku run rails db:seed
```

## Known limitations / next steps

- No real maps, live prices or opening hours (intentional — honest AI).
- Chat replies are non-streaming; quick-adjust is via free-text chat.
- Next: streaming responses, static map of stops, share/export a plan,
  city-grounded suggestions from a curated seed list.
