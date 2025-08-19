const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const pubsubName = 'product-pubsub';
const topicName = 'products';

app.post('/products', (req, res) => {
  const product = req.body;
  console.log('Product created:', product);

  fetch(`http://localhost:${daprPort}/v1.0/publish/${pubsubName}/${topicName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(product),
  })
  .then(() => {
    res.status(200).send('Product created and event published.');
  })
  .catch((error) => {
    console.error('Error publishing event:', error);
    res.status(500).send('Error publishing event.');
  });
});

const port = 3000;
app.listen(port, () => console.log(`Product service listening on port ${port}`));
