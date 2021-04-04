data {
  int<lower = 1> M;                   // augmented sample size
  int<lower = 1> T;                   // # primary periods
  int<lower = 1> maxJ;                // max # of secondary periods
  int<lower = 0, upper = maxJ> J[T];  // # 2ndary periods for each prim. period
  int<lower = 0, upper = 4> initial_state[M];
  int<lower = 1, upper = 3> trt_grp[M]; // 1: control, 2: new, 3: treated

  // observations
  // 0=NA, 1=detected upper, 2=detected lower, 3=not detected
  int<lower = 0, upper = 3> Y[M, T, maxJ];
  
  // dirichlet prior params
  vector<lower = 0>[3] alpha_init;
  
  int n_obs;
  vector[n_obs] obs_load;
  int<lower = 1, upper = T> obs_t[n_obs];
  int<lower = 1, upper = M> obs_i[n_obs];
  int n_unk;
  int<lower = 1, upper = T> unk_t[n_unk];
  int<lower = 1, upper = M> unk_i[n_unk];
}

transformed data {
  vector[M] initial_state_known;

  for (i in 1:M) {
    initial_state_known[i] = initial_state[i] > 0;
  }
}

parameters {
  // recruitment
  real<lower = 0> sd_recruit;
  vector[T] eps_recruitR;
  real mu_recruit;
  real<lower = 0, upper = 1> rec_upper;

  // survival
  real mu_srv;
  vector<upper = 0>[3] beta_srv_bd;
  vector[3] beta_srv;

  // detection params
  real mu_detect;
  real<lower = 0> sd_det;
  vector[T] eps_detR;

  // movement among sites
  real<lower = 0, upper = 1> pr_move_to_upper;
  real<lower = 0, upper = 1> pr_move_to_lower;
  
  simplex[3] initial_state_vec;
  
  // bd load params
  vector[T] mu_bdR;
  real<lower = 0> sd_bd;
  vector[3] bd_grp_adj; // 1: control, 2: new, 3: treated
  real<lower = 0> sd_bd_obs;
  vector[n_unk] unk_load;
}

transformed parameters {
  vector[M] log_lik;
  vector[4] pr_initial_state;
  matrix[M, T] load;
  vector[T] mu_bd = mu_bdR * sd_bd;
  vector[T] pr_recruit = inv_logit(mu_recruit + sd_recruit*eps_recruitR);
  vector[T] pr_recruit_upper = pr_recruit * rec_upper;
  vector[T] pr_recruit_lower = pr_recruit * (1 - rec_upper);
  vector[T] pr_detect = inv_logit(mu_detect + eps_detR * sd_det);
  matrix[4, 3] po[T];
  
  // observation matrix entries
  // y=1: detected at upper
  // y=2: detected at lower
  // y=3: not detected
  // indices are state (row), observation (column)
  for (t in 1:T) {
    po[t, 1, 1] = pr_detect[t];
    po[t, 1, 2] = 0;
    po[t, 1, 3] = 1 - pr_detect[t];
    po[t, 2, 1] = 0;
    po[t, 2, 2] = pr_detect[t];
    po[t, 2, 3] = 1 - pr_detect[t];
    po[t, 3, 1] = 0;
    po[t, 3, 2] = 0;
    po[t, 3, 3] = 1;
    po[t, 4, 1] = 0;
    po[t, 4, 2] = 0;
    po[t, 4, 3] = 1;
  }

  for (i in 1:n_obs) {
    load[obs_i[i], obs_t[i]] = obs_load[i];
  }
  
  for (i in 1:n_unk) {
    load[unk_i[i], unk_t[i]] = unk_load[i];
  }

  for (i in 1:3) {
    pr_initial_state[i] = initial_state_vec[i];
  }
  pr_initial_state[4] = 0; // individuals cannot be dead in first timestep
  
  // generate log likelihoods for observation histories
  {
    real acc[4];
    vector[4] gam[T];
    vector[4] ps[T, 4];
    vector[T] pr_survive;

    for (i in 1:M) {
      for (t in 1:T) {
        pr_survive[t] = inv_logit(
          mu_srv
          + beta_srv[trt_grp[i]]
          + beta_srv_bd[trt_grp[i]] * load[i, t]);
      }

      // s = 1 :: alive upper
      // s = 2 :: alive lower
      // s = 3 :: not recruited
      // s = 4 :: dead
      // transition matrix entries [s(t+1) | s(t)]
      // first index (rows): s(t)
      // second index (columns): s(t + 1)
      for (t in 1:T) {
        ps[t, 1, 1] = pr_survive[t] * (1 - pr_move_to_lower);
        ps[t, 1, 2] = pr_survive[t] * pr_move_to_lower;
        ps[t, 1, 3] = 0;
        ps[t, 1, 4] = 1 - pr_survive[t];
        ps[t, 2, 1] = pr_survive[t] * pr_move_to_upper;
        ps[t, 2, 2] = pr_survive[t] * (1 - pr_move_to_upper);
        ps[t, 2, 3] = 0;
        ps[t, 2, 4] = 1 - pr_survive[t];
        ps[t, 3, 1] = pr_recruit_upper[t];
        ps[t, 3, 2] = pr_recruit_lower[t];
        ps[t, 3, 3] = 1 - pr_recruit[t];
        ps[t, 3, 4] = 0;
        ps[t, 4, 1] = 0;
        ps[t, 4, 2] = 0;
        ps[t, 4, 3] = 0;
        ps[t, 4, 4] = 1;
      }

      for (t in 1:T) { // primary periods
        for (k in 1:4) { // state
          for (kk in 1:4) { // previous state
            if (t == 1) {
              if (initial_state_known[i]) {
                acc[kk] = initial_state[i] == kk;
              } else {
                acc[kk] = pr_initial_state[kk];
              }
            } else {
              acc[kk] = gam[t - 1, kk];
            }
            acc[kk] *= ps[t, kk, k];
            for (j in 1:J[t]) {
              acc[kk] *= po[t, k, Y[i, t, j]];
            }
          }
          gam[t, k] = sum(acc);
        }
      }
      log_lik[i] = log(sum(gam[T]));
    } // end loop over individuals
  } // end temporary scope
}

model {
  beta_srv_bd ~ std_normal();
  beta_srv ~ std_normal();
  mu_srv ~ std_normal();
  
  mu_detect ~ std_normal();
  eps_detR ~ std_normal();
  sd_det ~ std_normal();

  eps_recruitR ~ std_normal();
  mu_recruit ~ std_normal();
  sd_recruit ~ std_normal();
  
  pr_move_to_upper ~ beta(2, 20);
  pr_move_to_lower ~ beta(2, 20);
  
  mu_bdR ~ std_normal();
  sd_bd ~ std_normal();
  bd_grp_adj ~ std_normal();
  sd_bd_obs ~ std_normal();

  for (i in 1:M)
    load[i, ] ~ normal(mu_bd + bd_grp_adj[trt_grp[i]], sd_bd_obs); 

  target += sum(log_lik);
}


generated quantities {
  int<lower = 1, upper = 4> s[M, T];  // latent state
  int<lower=0> Nsuper;                // Superpopulation size
  int<lower=0> N[T];                // Actual population size


  {
    real acc[4];
    vector[4] gam[T];
    vector[4] ps[T, 4];
    vector[T] pr_survive;
    matrix[T, 4] forward;
    vector[4] tmp;

    for (i in 1:M) {
      for (t in 1:T) {
        pr_survive[t] = inv_logit(
          mu_srv
          + beta_srv[trt_grp[i]]
          + beta_srv_bd[trt_grp[i]] * load[i, t]);
      }

      // s = 1 :: alive upper
      // s = 2 :: alive lower
      // s = 3 :: not recruited
      // s = 4 :: dead
      // transition matrix entries [s(t+1) | s(t)]
      // first index (rows): s(t)
      // second index (columns): s(t + 1)
      for (t in 1:T) {
        ps[t, 1, 1] = pr_survive[t] * (1 - pr_move_to_lower);
        ps[t, 1, 2] = pr_survive[t] * pr_move_to_lower;
        ps[t, 1, 3] = 0;
        ps[t, 1, 4] = 1 - pr_survive[t];
        ps[t, 2, 1] = pr_survive[t] * pr_move_to_upper;
        ps[t, 2, 2] = pr_survive[t] * (1 - pr_move_to_upper);
        ps[t, 2, 3] = 0;
        ps[t, 2, 4] = 1 - pr_survive[t];
        ps[t, 3, 1] = pr_recruit_upper[t];
        ps[t, 3, 2] = pr_recruit_lower[t];
        ps[t, 3, 3] = 1 - pr_recruit[t];
        ps[t, 3, 4] = 0;
        ps[t, 4, 1] = 0;
        ps[t, 4, 2] = 0;
        ps[t, 4, 3] = 0;
        ps[t, 4, 4] = 1;
      }

      for (t in 1:T) { // primary periods
        for (k in 1:4) { // state
          for (kk in 1:4) { // previous state
            if (t == 1) {
              if (initial_state_known[i]) {
                acc[kk] = initial_state[i] == kk;
              } else {
                acc[kk] = pr_initial_state[kk];
              }
            } else {
              acc[kk] = gam[t - 1, kk];
            }
            acc[kk] *= ps[t, kk, k];
            for (j in 1:J[t]) {
              acc[kk] *= po[t, k, Y[i, t, j]];
            }
          }
          gam[t, k] = sum(acc);
        }
        forward[t, ] = gam[t, ]';
      }
  
      // backward sampling
      s[i, T] = categorical_rng(forward[T, ]' / sum(forward[T]));
      for(t_rev in 1:(T - 1)) {
        int t = T - t_rev;
        int tp1 = t + 1;
        tmp = forward[t,]' .* to_vector(ps[tp1, , s[i, tp1]]);
        s[i, t] = categorical_rng(tmp / sum(tmp));
      }
      if (initial_state_known[i]) {
        s[i, 1] = initial_state[i];
      }
    } // end loop over individuals
  } // end temporary scope

  {
    int al[M, T];
    int ever_alive[M];
    int w[M];

    for (i in 1:M) {
      for (t in 1:T) {
        al[i, t] = s[i, t] < 3;
      }
      ever_alive[i] = sum(al[i]) > 0;
    }
    Nsuper = sum(ever_alive);

    for (t in 1:T) {
      N[t] = sum(al[, t]);
    }
  }
}
