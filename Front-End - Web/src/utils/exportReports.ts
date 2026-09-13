// Weather Report Exporter Utility (CSV & PDF)

export interface WeatherReportData {
  location: string;
  date: string;
  temp: string;
  condition: string;
  humidity: number;
  wind: string;
  pressure: string;
  uv: number;
  rainChance: number;
  forecast: Array<{
    day: string;
    date: string;
    maxTemp: string;
    minTemp: string;
    condition: string;
    rainChance: number;
  }>;
}

export const exportWeatherCSV = (data: WeatherReportData) => {
  const headers = ['Date', 'Day', 'Location', 'Condition', 'Max Temp', 'Min Temp', 'Rain Chance (%)', 'Humidity (%)', 'Wind'];
  const rows = data.forecast.map(f => [
    f.date,
    f.day,
    `"${data.location}"`,
    `"${f.condition}"`,
    `"${f.maxTemp}"`,
    `"${f.minTemp}"`,
    f.rainChance,
    data.humidity,
    `"${data.wind}"`
  ]);

  const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', `WeatherGPT_Report_${data.location.replace(/[^a-zA-Z0-9]/g, '_')}_${data.date}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

export const exportWeatherPDF = (data: WeatherReportData) => {
  const printWindow = window.open('', '_blank');
  if (!printWindow) {
    alert('Please allow popups to download/print the PDF weather report.');
    return;
  }

  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>WeatherGPT Official Weather Report - ${data.location}</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 40px; color: #1e293b; background: #fff; }
          .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #3b82f6; padding-bottom: 20px; margin-bottom: 30px; }
          .logo { font-size: 28px; font-weight: 800; color: #2563eb; }
          .subtitle { font-size: 14px; color: #64748b; margin-top: 4px; }
          .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 24px; margin-bottom: 24px; }
          .hero-temp { font-size: 54px; font-weight: 900; color: #1e293b; }
          .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 16px; }
          .stat-item { background: #fff; padding: 12px 16px; border-radius: 12px; border: 1px solid #cbd5e1; }
          .stat-label { font-size: 11px; text-transform: uppercase; color: #64748b; font-weight: 700; }
          .stat-val { font-size: 18px; font-weight: 800; color: #0f172a; margin-top: 2px; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th { text-align: left; padding: 12px; background: #3b82f6; color: #fff; font-size: 12px; font-weight: 700; text-transform: uppercase; }
          td { padding: 12px; border-bottom: 1px solid #e2e8f0; font-size: 13px; font-weight: 600; }
          tr:nth-child(even) { background: #f8fafc; }
          .footer { text-align: center; margin-top: 40px; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 20px; }
        </style>
      </head>
      <body>
        <div class="header">
          <div>
            <div class="logo">WeatherGPT</div>
            <div class="subtitle">Official Weather Advisory & Multi-Lingual Climate Report</div>
          </div>
          <div style="text-align: right;">
            <div style="font-weight: 800; font-size: 16px;">${data.location}</div>
            <div style="font-size: 12px; color: #64748b;">Report Date: ${data.date}</div>
          </div>
        </div>

        <div class="card">
          <div style="display: flex; justify-content: space-between; align-items: center;">
            <div>
              <div style="font-size: 12px; font-weight: 700; text-transform: uppercase; color: #2563eb;">Current Live Conditions</div>
              <div class="hero-temp">${data.temp}</div>
              <div style="font-size: 20px; font-weight: 700; color: #475569;">${data.condition}</div>
            </div>
            <div style="text-align: right;">
              <div style="font-size: 14px; font-weight: 700; color: #16a34a;">Precipitation Prob: ${data.rainChance}%</div>
              <div style="font-size: 13px; color: #64748b; margin-top: 4px;">Humidity: ${data.humidity}% • Wind: ${data.wind}</div>
            </div>
          </div>

          <div class="grid">
            <div class="stat-item">
              <div class="stat-label">Humidity</div>
              <div class="stat-val">${data.humidity}%</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Wind Velocity</div>
              <div class="stat-val">${data.wind}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Atmospheric Pressure</div>
              <div class="stat-val">${data.pressure}</div>
            </div>
          </div>
        </div>

        <h3 style="font-size: 16px; font-weight: 800; color: #0f172a; margin-top: 30px;">7-Day Comprehensive Outlook</h3>
        <table>
          <thead>
            <tr>
              <th>Day & Date</th>
              <th>Condition</th>
              <th>High Temp</th>
              <th>Low Temp</th>
              <th>Rain Prob.</th>
            </tr>
          </thead>
          <tbody>
            ${data.forecast.map(f => `
              <tr>
                <td><strong>${f.day}</strong> (${f.date})</td>
                <td>${f.condition}</td>
                <td><span style="color: #ea580c;">${f.maxTemp}</span></td>
                <td><span style="color: #2563eb;">${f.minTemp}</span></td>
                <td><span style="color: #0284c7;">${f.rainChance}%</span></td>
              </tr>
            `).join('')}
          </tbody>
        </table>

        <div class="footer">
          Generated automatically by WeatherGPT Radar & Climate Engine • Verified Data Source
        </div>

        <script>
          window.onload = function() { window.print(); }
        </script>
      </body>
    </html>
  `;

  printWindow.document.write(html);
  printWindow.document.close();
};
