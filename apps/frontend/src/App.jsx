import React, { useEffect, useState } from "react";

const API_BASE = ""; // routé par l'ingress sur /api/*

export default function App() {
  const [sites, setSites] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [selectedSite, setSelectedSite] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch(`${API_BASE}/api/sites`)
      .then(r => r.json())
      .then(d => setSites(d.sites || []))
      .catch(e => setError(e.message));
  }, []);

  useEffect(() => {
    if (!selectedSite) return;
    fetch(`${API_BASE}/api/rooms?site_id=${selectedSite}`)
      .then(r => r.json())
      .then(d => setRooms(d.rooms || []));
  }, [selectedSite]);

  return (
    <main style={{ fontFamily: "system-ui, sans-serif", maxWidth: 800, margin: "2rem auto", padding: "0 1rem" }}>
      <h1>SalleEnFrance</h1>
      <p>Réservez une salle de réunion sur l'un de nos sites en France.</p>
      {error && <p style={{ color: "crimson" }}>Erreur : {error}</p>}
      <h2>Sites</h2>
      <ul>
        {sites.map(s => (
          <li key={s.id}>
            <button onClick={() => setSelectedSite(s.id)}>
              {s.name} — {s.city} ({s.region})
            </button>
          </li>
        ))}
      </ul>
      {selectedSite && (
        <>
          <h2>Salles disponibles</h2>
          <ul>
            {rooms.map(r => (
              <li key={r.id}>{r.name} — {r.capacity} places</li>
            ))}
          </ul>
        </>
      )}
    </main>
  );
}
