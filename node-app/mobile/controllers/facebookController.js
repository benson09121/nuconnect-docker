const axios = require('axios');
require('dotenv').config();

async function getFacebookPosts(req, res) {
    axios.get(`https://graph.facebook.com/v22.0/${process.env.FB_GROUP_ID}/feed?fields=message,created_time,full_picture,permalink_url&access_token=${process.env.FB_ACCESS_TOKEN}`).then((response) => {
        res.json(response.data.data);
    }).catch((error) => {
        res.status(500).json({ message: error.message });
    })
}

module.exports = { getFacebookPosts };
