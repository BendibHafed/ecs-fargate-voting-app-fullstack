def test_health(client):
    resp = client.get('/healthz')
    assert resp.status_code == 200
    assert resp.get_json()['status'] == 'ok'

def test_register_and_login(client):
    # Register
    r = client.post('/register', json={
        'email': 'newuser@example.com',
        'password': 'pass123'
    })
    assert r.status_code == 200

    # Login
    r = client.post('/login', json={
        'email': 'newuser@example.com',
        'password': 'pass123'
    })
    assert r.status_code == 200
    assert r.get_json()['status'] == 'logged_in'

def test_vote_flow(client):
    # Login first
    r = client.post('/login', json={
        'email': 'test@example.com',
        'password': 'secret'
    })
    assert r.status_code == 200

    # Get polls
    r = client.get('/api/polls')
    assert r.status_code == 200
    polls = r.get_json()
    assert len(polls) == 1
    pid = polls[0]['id']

    # Get choices
    r = client.get(f'/api/polls/{pid}/choices')
    choices = r.get_json()
    assert len(choices) >= 2
    cid = choices[0]['id']

    # Vote
    r = client.post(f'/api/polls/{pid}/vote', json={'choice_id': cid})
    assert r.status_code == 200

    # Verify vote count
    r = client.get(f'/api/polls/{pid}/choices')
    updated = r.get_json()
    voted = next(c for c in updated if c['id'] == cid)
    assert voted['votes'] == 1
