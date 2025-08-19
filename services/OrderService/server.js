const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json({ type: 'application/cloudevents+json' }));

const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const pubsubName = 'product-pubsub';
const topicName = 'products';

let receivedProducts = [];

app.get('/dapr/subscribe', (req, res) => {
  res.json([
    {
      pubsubname: pubsubName,
      topic: topicName,
      route: 'products'
    }
  ]);
});

app.post('/products', (req, res) => {
  console.log('Received product:', req.body.data);
  receivedProducts.push(req.body.data);
  res.sendStatus(200);
});

app.get('/orders', (req, res) => {
  res.json(receivedProducts);
});

const port = 3001;
app.listen(port, () => console.log(`Order service listening on port ${port}`));
